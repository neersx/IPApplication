using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Extentions;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Core
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.MaintainNumberTypes)]
    [RoutePrefix("api/configuration/numbertypes")]
    public class NumberTypeMaintenanceController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IInprotechVersionChecker _inprotechVersionChecker;

        static readonly CommonQueryParameters DefaultQueryParameters =
           CommonQueryParameters.Default.Extend(new CommonQueryParameters
           {
               SortBy = "DisplayPriority",
               SortDir = "asc"
           });

        public NumberTypeMaintenanceController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IInprotechVersionChecker inprotechVersionChecker)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _inprotechVersionChecker = inprotechVersionChecker;
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        public dynamic ViewData()
        {
            var maxNumberTypeLength = _inprotechVersionChecker.CheckMinimumVersion(16) ? NumberTypeMetadata.CodeLength : NumberTypeMetadata.LegacyCodeLength;

            return new { MaxNumberTypeLength = maxNumberTypeLength };
        }

        [HttpGet]
        [Route("search")]
        [NoEnrichment]
        public dynamic Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SearchOptions searchOptions,
                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            var culture = _preferredCultureResolver.Resolve();
            var protectedNumberTypes = _dbContext.Set<ProtectCodes>().Where(_ => !string.IsNullOrEmpty(_.NumberTypeId)).Select(_ => _.NumberTypeId).Distinct();

            var results = _dbContext.Set<NumberType>().Select(_ => new
            {
                Code = _.NumberTypeCode,
                _.IssuedByIpOffice,
                RelatedEvent = DbFuncs.GetTranslation(_.RelatedEvent.Description, null, _.RelatedEvent.DescriptionTId, culture),
                _.Id,
                Description = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture) ?? string.Empty,
                _.DisplayPriority,
                IsProtected = protectedNumberTypes.Contains(_.NumberTypeCode)
            }).AsEnumerable();

            if (!string.IsNullOrEmpty(searchOptions?.Text))
                results = results.Where(x =>
                    x.Code.Equals(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase)
                    || x.Description.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1);
            
            return results.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
        }

        [HttpPut]
        [Route("update-number-types-sequence")]
        public dynamic UpdateNumberTypesSequence(DisplayOrderSaveDetails[] saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            var filtered = _dbContext.Set<NumberType>();

            foreach (var record in filtered)
            {
                var numberType = saveDetails.SingleOrDefault(_ => _.Id == record.Id);
                if(numberType!=null) record.DisplayPriority = numberType.DisplayPriority;
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = "success"
            };
        }

        [HttpGet]
        [Route("{id}")]
        [NoEnrichment]
        public dynamic GetNumberType(int id)
        {
            var culture = _preferredCultureResolver.Resolve();
            var numberType = _dbContext.Set<NumberType>().Select(_ => new NumberTypeSaveDetails
                                                                 {
                                                                     Id = _.Id,
                                                                     NumberTypeCode = _.NumberTypeCode,
                                                                     NumberTypeDescription = _.Name,
                                                                     IssuedByIpOffice = _.IssuedByIpOffice,
                                                                     DisplayPriority = _.DisplayPriority,
                                                                     DataItem = _.DocItemId != null ? new DataItem
                                                                     {
                                                                         Key = _.DocItem.Id,
                                                                         Code = _.DocItem.Name,
                                                                         Value = DbFuncs.GetTranslation(_.DocItem.Description, null,
                                                                                                        _.DocItem.ItemDescriptionTId, culture) ?? string.Empty
                                                                     }
                                                                    : null,
                                                                     RelatedEvent = _.RelatedEventId != null ? new Event
                                                                     {
                                                                         Key = _.RelatedEvent.Id,
                                                                         Code = _.RelatedEvent.Code,
                                                                         Value = DbFuncs.GetTranslation(_.RelatedEvent.Description, null,
                                                                                                        _.RelatedEvent.DescriptionTId, culture) ?? string.Empty
                                                                     }
                                                                    : null
                                                                 }).SingleOrDefault(_ => _.Id == id);

            if (numberType == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);
            return numberType;
        }

        [HttpPost]
        [Route("")]
        public dynamic Save(NumberTypeSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));
            Infrastructure.Validations.ValidationError[] validationErrors;
            if (_inprotechVersionChecker.CheckMinimumVersion(16))
            {
                validationErrors = Validate(saveDetails, Operation.Add).ToArray();
            }
            else
            {
                var s = new LegacyNumberTypeSaveDetails
                {
                    Id = saveDetails.Id,
                    NumberTypeCode = saveDetails.NumberTypeCode,
                    NumberTypeDescription = saveDetails.NumberTypeDescription,
                    IssuedByIpOffice = saveDetails.IssuedByIpOffice,
                    RelatedEvent = saveDetails.RelatedEvent,
                    DisplayPriority = saveDetails.DisplayPriority,
                    DataItem = saveDetails.DataItem
                };
                validationErrors = Validate(s, Operation.Add).ToArray();
            }
            if (!validationErrors.Any())
            {
                short displayPriority = -1;
                if(_dbContext.Set<NumberType>().Any())      
                    displayPriority = _dbContext.Set<NumberType>().Max(m => m.DisplayPriority);

                var numberType = new NumberType(saveDetails.NumberTypeCode, saveDetails.NumberTypeDescription, saveDetails.RelatedEvent?.Key)
                {
                    DocItemId = saveDetails.DataItem?.Key,
                    IssuedByIpOffice = saveDetails.IssuedByIpOffice,
                    DisplayPriority = ++displayPriority
                };

                _dbContext.Set<NumberType>().Add(numberType);
                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    UpdatedId = numberType.Id
                };
            }

            return validationErrors.AsErrorResponse();
        }

        [HttpPut]
        [Route("{id}")]
        public dynamic Update(short id, NumberTypeSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));
            Infrastructure.Validations.ValidationError[] validationErrors;
            if (_inprotechVersionChecker.CheckMinimumVersion(16))
            {
                validationErrors = Validate(saveDetails, Operation.Update).ToArray();
            }
            else
            {
                var s = new LegacyNumberTypeSaveDetails
                {
                    Id = saveDetails.Id,
                    NumberTypeCode = saveDetails.NumberTypeCode,
                    NumberTypeDescription = saveDetails.NumberTypeDescription,
                    IssuedByIpOffice = saveDetails.IssuedByIpOffice,
                    RelatedEvent = saveDetails.RelatedEvent,
                    DisplayPriority = saveDetails.DisplayPriority,
                    DataItem = saveDetails.DataItem
                };
                validationErrors = Validate(s, Operation.Update).ToArray();
            }

            if (!validationErrors.Any())
            {
                var entityToUpdate = _dbContext.Set<NumberType>().First(_ => _.Id == id);
              
                entityToUpdate.DocItemId = saveDetails.DataItem?.Key;
                entityToUpdate.RelatedEventId = saveDetails.RelatedEvent?.Key;
                entityToUpdate.IssuedByIpOffice = saveDetails.IssuedByIpOffice;
                entityToUpdate.Name = saveDetails.NumberTypeDescription;

                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    UpdatedId = entityToUpdate.Id
                };
            }

            return validationErrors.AsErrorResponse();
        }

        [HttpPut]
        [Route("{id}/numbertypecode")]
        public dynamic UpdateNumberTypeCode(int id, ChangeNumberTypeCodeDetails changeNumberTypeCodeDetails)
        {
            if (changeNumberTypeCodeDetails == null) throw new ArgumentNullException(nameof(changeNumberTypeCodeDetails));
            Infrastructure.Validations.ValidationError[] validationErrors;
            if (_inprotechVersionChecker.CheckMinimumVersion(16))
            {
                validationErrors = ValidateChangeNumberType(changeNumberTypeCodeDetails).ToArray();
            }
            else
            {
                var s = new LegacyChangeNumberTypeCodeDetails
                {
                    Id = changeNumberTypeCodeDetails.Id,
                    NumberTypeCode = changeNumberTypeCodeDetails.NumberTypeCode,
                    NewNumberTypeCode = changeNumberTypeCodeDetails.NewNumberTypeCode
                };
                validationErrors = ValidateChangeNumberType(s).ToArray();
            }
            
            if (!validationErrors.Any())
            {
                var sqlCommand = _dbContext.CreateStoredProcedureCommand("nt_ChangeNumberType");
                sqlCommand.CommandTimeout = 0;
                sqlCommand.Parameters.AddRange(
                                                new[]
                                                {
                                                new SqlParameter("@psOldNumberType", changeNumberTypeCodeDetails.NumberTypeCode),
                                                new SqlParameter("@psNewNumberType", changeNumberTypeCodeDetails.NewNumberTypeCode)
                                                });

                sqlCommand.ExecuteNonQuery();

                return new
                {
                    Result = "success",
                    UpdatedId = _dbContext.Set<NumberType>().Single(_=> _.NumberTypeCode == changeNumberTypeCodeDetails.NewNumberTypeCode).Id
                };
            }

            return validationErrors.AsErrorResponse();
        }

        [HttpPost]
        [Route("delete")]
        [NoEnrichment]
        public DeleteResponseModel Delete(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var numberTypes = _dbContext.Set<NumberType>().
                                            Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();

                response.InUseIds = new List<int>();

                foreach (var numberType in numberTypes)
                {
                    try
                    {
                        _dbContext.Set<NumberType>().Remove(numberType);
                        _dbContext.SaveChanges();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(numberType.Id);
                        }
                        _dbContext.Detach(numberType);
                    }
                }

                txScope.Complete();

                if (response.InUseIds.Any())
                {
                    response.HasError = true;
                    response.Message = ConfigurationResources.InUseErrorMessage;
                    return response;
                }
            }
            return response;
        }

        IEnumerable<Infrastructure.Validations.ValidationError> ValidateChangeNumberType(LegacyChangeNumberTypeCodeDetails changeNumberTypeCodeDetails)
        {
            foreach (var validationError in CommonValidations.Validate(changeNumberTypeCodeDetails))
                yield return validationError;

            foreach (var vr in CheckForErrors(changeNumberTypeCodeDetails.Id, changeNumberTypeCodeDetails.NewNumberTypeCode, Operation.Add)) yield return vr;
        }

        IEnumerable<Infrastructure.Validations.ValidationError> Validate(LegacyNumberTypeSaveDetails numberType, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(numberType))
                yield return validationError;

            foreach (var vr in CheckForErrors(numberType.Id, numberType.NumberTypeCode, operation)) yield return vr;
        }

        IEnumerable<Infrastructure.Validations.ValidationError> CheckForErrors(int id, string code, Operation operation)
        {
            var all = _dbContext.Set<NumberType>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != id))
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var others = operation == Operation.Update ? all.Where(_ => _.Id != id).ToArray() : all;
            if (others.Any(_ => _.NumberTypeCode.IgnoreCaseEquals(code)))
            {
                yield return ValidationErrors.NotUnique(string.Format(Resources.ErrorDuplicateNumberTypeCode, code),"numberTypeCode");
            }
        }
    }

    public class DisplayOrderSaveDetails
    {
        public int Id { get; set; }
        public short DisplayPriority { get; set; }
    }

    public class NumberTypeSaveDetails : LegacyNumberTypeSaveDetails
    {
        [Required]
        [MaxLength(NumberTypeMetadata.CodeLength)]
        public new string NumberTypeCode
        {
            get => base.NumberTypeCode;
            set => base.NumberTypeCode = value;
        }
    }

    public class LegacyNumberTypeSaveDetails
    {
        public int Id { get; set; }

        [Required]
        [MaxLength(NumberTypeMetadata.LegacyCodeLength)]
        public string NumberTypeCode { get; set; }

        [Required]
        [MaxLength(30)]
        public string NumberTypeDescription { get; set; }

        public bool IssuedByIpOffice { get; set; }

        public Event RelatedEvent { get; set; }

        public short? DisplayPriority { get; set; }

        public DataItem DataItem { get; set; }

    }

    public class ChangeNumberTypeCodeDetails : LegacyChangeNumberTypeCodeDetails
    {
        [Required]
        [MaxLength(NumberTypeMetadata.CodeLength)]
        public new string NewNumberTypeCode
        {
            get => base.NewNumberTypeCode;
            set => base.NewNumberTypeCode = value;
        }
    }

    public class LegacyChangeNumberTypeCodeDetails
    {
        public int Id { get; set; }

        [Required]
        public string NumberTypeCode { get; set; }

        [Required]
        [MaxLength(NumberTypeMetadata.LegacyCodeLength)]
        public string NewNumberTypeCode { get; set; }
    }

    internal static class NumberTypeMetadata
    {
        internal const int LegacyCodeLength = 1;
        internal const int CodeLength = 3;
    }
}
