using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Extentions;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using TextType = InprotechKaizen.Model.Cases.TextType;

namespace Inprotech.Web.Configuration.Core
{

    [Authorize]
    [RequiresAccessTo(ApplicationTask.MaintainTextTypes)]
    [RoutePrefix("api/configuration/texttypes")]

    public class TextTypeMaintenanceController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        static readonly CommonQueryParameters DefaultQueryParameters =
          CommonQueryParameters.Default.Extend(new CommonQueryParameters
          {
              SortBy = "Id",
              SortDir = "asc"
          });

        public TextTypeMaintenanceController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            if (preferredCultureResolver == null) throw new ArgumentNullException(nameof(preferredCultureResolver));

            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        public dynamic ViewData()
        {
            return null;
        }

        [HttpGet]
        [Route("search")]
        [NoEnrichment]
        public dynamic Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SearchOptions searchOptions,
                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);
            var culture = _preferredCultureResolver.Resolve();
            var protectedTextTypes = _dbContext.Set<ProtectCodes>().Where(_ => !string.IsNullOrEmpty(_.TextTypeId)).Select(_ => _.TextTypeId).Distinct();

            var results = _dbContext.Set<TextType>().ToArray().Select(_ => new 
            {
                _.Id,
                Description = DbFuncs.GetTranslation(string.Empty, _.TextDescription, _.TextDescriptionTId, culture),
                _.UsedByCase,
                UsedByName = _.UsedByEmployee || _.UsedByIndividual || _.UsedByOrganisation,
                _.UsedByEmployee,
                _.UsedByIndividual,
                _.UsedByOrganisation,
                IsProtected = protectedTextTypes.Contains(_.Id)
            }).AsEnumerable();

            if (!string.IsNullOrEmpty(searchOptions?.Text))
                results = results.Where(x =>
                    x.Id.Equals(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase)
                    || x.Description.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1);

            return results.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
        }

        [HttpGet]
        [Route("{id}")]
        [NoEnrichment]
        public dynamic GetTextType(string id)
        {
            var selectedTextType = _dbContext.Set<TextType>().SingleOrDefault(_ => Equals(_.Id, id));
            if (selectedTextType == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            return new TextTypeModel
            {
                Id = selectedTextType.Id,
                Description = selectedTextType.TextDescription,
                UsedByCase = selectedTextType.UsedByCase,
                UsedByName = selectedTextType.UsedByIndividual || selectedTextType.UsedByEmployee || selectedTextType.UsedByOrganisation,
                UsedByIndividual = selectedTextType.UsedByIndividual,
                UsedByEmployee = selectedTextType.UsedByEmployee,
                UsedByOrganisation = selectedTextType.UsedByOrganisation
            };
        }

        [HttpPost]
        [Route("")]
        public dynamic Save(TextTypeModel saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            var validationErrors = Validate(saveDetails, Operation.Add).ToArray();
            if (validationErrors.Any()) return validationErrors.AsErrorResponse();
            var textType = new TextType(saveDetails.Description)
            {
                Id = saveDetails.Id,
                UsedByFlag = GetUsedByFlag(saveDetails)
            };

            _dbContext.Set<TextType>().Add(textType);
            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedId = textType.Id
            };
        }

        [HttpPut]
        [Route("{id}")]
        public dynamic Update(string id, TextTypeModel saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));
            var validationErrors = Validate(saveDetails, Operation.Update).ToArray();
            if (!validationErrors.Any())
            {
                var entityToUpdate = _dbContext.Set<TextType>().First(_ => _.Id == id);

                entityToUpdate.TextDescription = saveDetails.Description;
                entityToUpdate.UsedByFlag = GetUsedByFlag(saveDetails);

                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    UpdatedId = entityToUpdate.Id
                };
            }

            return validationErrors.AsErrorResponse();
        }

        static short? GetUsedByFlag(TextTypeModel model)
        {
            if (!model.UsedByName || (!model.UsedByEmployee && !model.UsedByIndividual && !model.UsedByOrganisation)) return null;

            return Convert.ToInt16((Convert.ToInt16(model.UsedByEmployee) * (short)KnownTextTypeUsedBy.Employee)
                   | (Convert.ToInt16(model.UsedByIndividual) * (short)KnownTextTypeUsedBy.Individual)
                   | (Convert.ToInt16(model.UsedByOrganisation) * (short)KnownTextTypeUsedBy.Organisation));
        }

        [HttpPost]
        [Route("delete")]
        [NoEnrichment]
        public TextTypeDeleteResponseModel Delete(TextTypeDeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new TextTypeDeleteResponseModel();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var textTypes = _dbContext.Set<TextType>().
                                            Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();

                if(!textTypes.Any()) throw new HttpResponseException(HttpStatusCode.NotFound);

                response.InUseIds = new List<string>();

                foreach (var textType in textTypes)
                {
                    try
                    {
                        _dbContext.Set<TextType>().Remove(textType);
                        _dbContext.SaveChanges();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(textType.Id);
                        }
                        _dbContext.Detach(textType);
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

        IEnumerable<Infrastructure.Validations.ValidationError> Validate(TextTypeModel textType, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(textType))
                yield return validationError;

            foreach (var vr in CheckForErrors(textType.Id, operation)) yield return vr;
        }

        IEnumerable<Infrastructure.Validations.ValidationError> CheckForErrors(string code, Operation operation)
        {
            var all = _dbContext.Set<TextType>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != code))
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var others = operation == Operation.Update ? all.Where(_ => _.Id != code).ToArray() : all;
            if (others.Any(_ => _.Id.IgnoreCaseEquals(code)))
            {
                yield return ValidationErrors.NotUnique(string.Format(Resources.ErrorDuplicateTextTypeCode, code), "textTypeCode");
            }
        }

        [HttpPut]
        [Route("{id}/texttypecode")]
        public dynamic UpdateTextTypeCode(string id, ChangeTextTypeCodeDetails changeTextTypeCodeDetails)
        {
            if (changeTextTypeCodeDetails == null) throw new ArgumentNullException(nameof(changeTextTypeCodeDetails));
            var validationErrors = ValidateChangeTextType(changeTextTypeCodeDetails).ToArray();

            if (validationErrors.Any()) return validationErrors.AsErrorResponse();
            var sqlCommand = _dbContext.CreateStoredProcedureCommand("tt_ChangeTextType");
            sqlCommand.CommandTimeout = 0;
            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               new SqlParameter("@psOldTextType", changeTextTypeCodeDetails.Id),
                                               new SqlParameter("@psNewTextType", changeTextTypeCodeDetails.NewTextTypeCode),
                                               new SqlParameter("@pbRemoveOldTextType", true), 
                                           });

            sqlCommand.ExecuteNonQuery();

            return new
            {
                Result = "success",
                UpdatedId = changeTextTypeCodeDetails.NewTextTypeCode
            };
        }

        IEnumerable<Infrastructure.Validations.ValidationError> ValidateChangeTextType(ChangeTextTypeCodeDetails changeTextTypeCodeDetails)
        {
            foreach (var validationError in CommonValidations.Validate(changeTextTypeCodeDetails))
                yield return validationError;

            foreach (var vr in CheckForErrors(changeTextTypeCodeDetails.NewTextTypeCode, Operation.Add)) yield return vr;
        }
    }

    public class TextTypeModel
    {
        [Required]
        [MaxLength(2)]
        public string Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Description { get; set; }

        public bool UsedByCase { get; set; }

        public bool UsedByName { get; set; }

        public bool UsedByEmployee { get; set; }

        public bool UsedByIndividual { get; set; }

        public bool UsedByOrganisation { get; set; }

    }

    public class TextTypeDeleteRequestModel
    {
        public List<string> Ids { get; set; }
    }

    public class TextTypeDeleteResponseModel
    {
        public List<string> InUseIds { get; set; }
        public bool HasError { get; set; }
        public string Message { get; set; }
    }

    public class ChangeTextTypeCodeDetails
    {
        [Required]
        [MaxLength(2)]
        public string Id { get; set; }

        [Required]
        [MaxLength(2)]
        public string NewTextTypeCode { get; set; }
    }
}
