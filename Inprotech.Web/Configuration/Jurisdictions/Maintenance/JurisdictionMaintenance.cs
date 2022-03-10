using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data.SqlClient;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Extentions;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Jurisdictions.Maintenance
{
    public interface IJurisdictionMaintenance
    {
        dynamic Save(JurisdictionModel formData, Operation operation);
        dynamic Delete(IEnumerable<string> ids);

        dynamic UpdateJurisdictionCode(ChangeJurisdictionCodeDetails changeJurisdictionCodeDetails);
    }
    public class JurisdictionMaintenance : IJurisdictionMaintenance
    {
        readonly IDbContext _dbContext;
        readonly IGroupMembershipMaintenance _groupMembershipMaintenance;
        readonly ITextsMaintenance _textsMaintenance;
        readonly IOverviewMaintenance _overviewMaintenance;
        readonly IAttributesMaintenance _attributesMaintenance;
        readonly IStatusFlagsMaintenance _statusFlagsMaintenance;
        readonly IClassesMaintenance _classesMaintenance;
        readonly IStateMaintenance _stateMaintenance;
        readonly ICountryHolidayMaintenance _countryHolidayMaintenance;
        readonly IValidNumbersMaintenance _validaNumbersMaintenance;

        public JurisdictionMaintenance(IDbContext dbContext, IGroupMembershipMaintenance groupMembershipMaintenance, IOverviewMaintenance overviewMaintenance,
                                        IAttributesMaintenance attributesMaintenance, ITextsMaintenance textsMaintenance,
                                        IStatusFlagsMaintenance statusFlagsMaintenance, IClassesMaintenance classesMaintenance,
                                        IStateMaintenance stateMaintenance, ICountryHolidayMaintenance countryHolidayMaintenance,IValidNumbersMaintenance validaNumbersMaintenance)
        {
            _dbContext = dbContext;
            _groupMembershipMaintenance = groupMembershipMaintenance;
            _overviewMaintenance = overviewMaintenance;
            _textsMaintenance = textsMaintenance;
            _attributesMaintenance = attributesMaintenance;
            _statusFlagsMaintenance = statusFlagsMaintenance;
            _classesMaintenance = classesMaintenance;
            _stateMaintenance = stateMaintenance;
            _validaNumbersMaintenance = validaNumbersMaintenance;
            _countryHolidayMaintenance = countryHolidayMaintenance;
        }

        public dynamic Save(JurisdictionModel formData, Operation operation)
        {
            var errors = Validate(formData, operation).ToArray();

            if (errors.Any())
            {
                return new { Result = errors.AsErrorResponse() };
            }

            IList<JurisdictionSaveResponseModel> saveResponse = new List<JurisdictionSaveResponseModel>();
            using (var tcs = _dbContext.BeginTransaction())
            {
                _overviewMaintenance.Save(formData, operation);

                if (formData.GroupMembershipDelta != null)
                    _groupMembershipMaintenance.Save(formData.GroupMembershipDelta);
                if(formData.TextsDelta !=null)
                    _textsMaintenance.Save(formData.TextsDelta);
                if (formData.AttributesDelta != null)
                    _attributesMaintenance.Save(formData.AttributesDelta);
                if(formData.StatusFlagsDelta != null)
                    _statusFlagsMaintenance.Save(formData.StatusFlagsDelta);
                if (formData.ClassesDelta != null)
                    _classesMaintenance.Save(formData.ClassesDelta);
                if (formData.StateDelta != null)
                    saveResponse.Add(_stateMaintenance.Save(formData.StateDelta));
                if (formData.ValidNumbersDelta != null)
                    _validaNumbersMaintenance.Save(formData.ValidNumbersDelta);

                _dbContext.SaveChanges();

                tcs.Complete();
            }
            return new
            {
                Result = "success",
                formData.Id,
                SaveResponse = saveResponse,
                HasInUseItems = saveResponse.Any(item => item != null && item?.InUseItems.Count > 0)
            };
        }

        public dynamic Delete(IEnumerable<string> ids)
        {
            var deletedJurisdiction = _dbContext.Set<Country>().Where(v => ids.Contains(v.Id)).ToList();

            var errors = new List<ValidationError>();

            foreach (var item in deletedJurisdiction)
            {
                try
                {
                    using (var tcs = _dbContext.BeginTransaction())
                    {
                        _dbContext.Set<Country>().Remove(item);

                        _dbContext.SaveChanges();
                        tcs.Complete();
                    }
                }
                catch (Exception ex)
                {
                    var sqlException = ex.FindInnerException<SqlException>();
                    if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                    {
                        errors.Add(new ValidationError(null, "code", item.Id, item.Name));
                    }
                    _dbContext.Detach(item);
                }
            }

            if (errors.Any())
                return errors.AsErrorResponse();

            return new
            {
                Result = "success"
            };
        }

        public IEnumerable<ValidationError> Validate(JurisdictionModel formData, Operation operation)
        {
            var errors = new List<ValidationError>();
            errors.AddRange(_overviewMaintenance.Validate(formData, operation));
            if (formData.GroupMembershipDelta != null)
                errors.AddRange(_groupMembershipMaintenance.Validate(formData.GroupMembershipDelta));
            if (formData.AttributesDelta != null)
                errors.AddRange(_attributesMaintenance.Validate(formData.AttributesDelta, formData.Attributes));
            if (formData.TextsDelta != null)
                errors.AddRange(_textsMaintenance.Validate(formData.TextsDelta));
            if (formData.StatusFlagsDelta != null)
                errors.AddRange(_statusFlagsMaintenance.Validate(formData.StatusFlagsDelta));
            if (formData.ClassesDelta != null)
                errors.AddRange(_classesMaintenance.Validate(formData.ClassesDelta));
            if (formData.StateDelta != null)
                errors.AddRange(_stateMaintenance.Validate(formData.StateDelta));
            if (formData.ValidNumbersDelta != null)
                errors.AddRange(_validaNumbersMaintenance.Validate(formData.ValidNumbersDelta));
            return errors;
        }

        public dynamic UpdateJurisdictionCode(ChangeJurisdictionCodeDetails changeJurisdictionCodeDetails)
        {
            if (changeJurisdictionCodeDetails == null) throw new ArgumentNullException(nameof(changeJurisdictionCodeDetails));
            var validationErrors = ValidateChangeJurisdictionCode(changeJurisdictionCodeDetails).ToArray();

            if (!validationErrors.Any())
            {
                var sqlCommand = _dbContext.CreateStoredProcedureCommand("cn_ChangeCountryCode");
                sqlCommand.CommandTimeout = 0;
                sqlCommand.Parameters.AddRange(
                                               new[]
                                               {
                                                   new SqlParameter("@psOldCountryCode", changeJurisdictionCodeDetails.JurisdictionCode),
                                                   new SqlParameter("@psNewCountryCode", changeJurisdictionCodeDetails.NewJurisdictionCode)
                                               });

                sqlCommand.ExecuteNonQuery();

                return new
                {
                    Result = "success"
                };
            }

            return validationErrors.AsErrorResponse();
        }

        IEnumerable<ValidationError> ValidateChangeJurisdictionCode(ChangeJurisdictionCodeDetails changeJurisdictionCodeDetails)
        {
            foreach (var validationError in CommonValidations.Validate(changeJurisdictionCodeDetails))
                yield return validationError;

            foreach (var vr in CheckForErrors(changeJurisdictionCodeDetails.NewJurisdictionCode, Operation.Add)) yield return vr;
        }

        IEnumerable<ValidationError> CheckForErrors(string code, Operation operation)
        {
            var all = _dbContext.Set<Country>().ToArray();

            var others = operation == Operation.Update ? all.Where(_ => _.Id != code).ToArray() : all;
            if (others.Any(_ => _.Id.IgnoreCaseEquals(code)))
            {
                yield return ValidationErrors.NotUnique(string.Format(ConfigurationResources.ErrorDuplicateJurisdictionCode, code), "jurisdiction");
            }
        }
    }

    public class JurisdictionSaveResponseModel
    {
        public string TopicName { get; set; }
        public dynamic InUseItems { get; set; }
    }

    public class ChangeJurisdictionCodeDetails
    {
        [Required]
        [MaxLength(3)]
        public string JurisdictionCode { get; set; }

        [Required]
        [MaxLength(3)]
        public string NewJurisdictionCode { get; set; }
    }
}
