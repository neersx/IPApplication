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
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Extentions;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using ValidationError = Inprotech.Infrastructure.Validations.ValidationError;

namespace Inprotech.Web.Configuration.Names
{
    [Authorize]
    [RoutePrefix("api/configuration/names/aliastype")]

    public class AliasTypeController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        static readonly CommonQueryParameters DefaultQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Description",
                SortDir = "asc"
            });

        public AliasTypeController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainNameAliasTypes, ApplicationTaskAccessLevel.None)]
        public dynamic ViewData()
        {
            return null;
        }

        [HttpGet]
        [Route("search")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainNameAliasTypes, ApplicationTaskAccessLevel.None)]
        public dynamic Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SearchOptions searchOptions,
                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);
            var culture = _preferredCultureResolver.Resolve();

            var results = _dbContext.Set<NameAliasType>().ToArray().Select(_ => new
            {
                _.Id,
                _.Code,
                Description = DbFuncs.GetTranslation(string.Empty, _.Description, _.AliasDescriptionTId, culture),
                _.IsUnique
            }).AsEnumerable();

            if (!string.IsNullOrEmpty(searchOptions?.Text))
                results = results.Where(x =>
                                            x.Code.Equals(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase)
                                            || x.Description.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1);

            return results.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
        }

        [HttpGet]
        [Route("{id}")]
        [NoEnrichment]
        public dynamic GetNameAliasType(int id)
        {
            var selectedNameAliasType = _dbContext.Set<NameAliasType>().SingleOrDefault(_ => _.Id == id);
            if (selectedNameAliasType == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            return new NameAliasTypeModel
            {
                Id = selectedNameAliasType.Id,
                Code = selectedNameAliasType.Code,
                Description = selectedNameAliasType.Description,
                IsUnique = selectedNameAliasType.IsUnique

            };
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainNameAliasTypes, ApplicationTaskAccessLevel.Create)]
        public dynamic Save(NameAliasTypeModel saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            var validationErrors = Validate(saveDetails, Operation.Add).ToArray();
            if (validationErrors.Any()) return validationErrors.AsErrorResponse();
            var aliasType = new NameAliasType
            {
                Code = saveDetails.Code,
                Description = saveDetails.Description,
                IsUnique = saveDetails.IsUnique
            };

            _dbContext.Set<NameAliasType>().Add(aliasType);
            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedId = aliasType.Code
            };
        }

        [HttpPut]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainNameAliasTypes, ApplicationTaskAccessLevel.Modify)]
        public dynamic Update(int id, NameAliasTypeModel saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));
            var validationErrors = Validate(saveDetails, Operation.Update).ToArray();
            if (!validationErrors.Any())
            {
                var entityToUpdate = _dbContext.Set<NameAliasType>().First(_ => _.Id == id);

                entityToUpdate.Description = saveDetails.Description;
                entityToUpdate.IsUnique = saveDetails.IsUnique;

                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    UpdatedId = entityToUpdate.Code
                };
            }

            return validationErrors.AsErrorResponse();
        }

        [HttpPost]
        [Route("delete")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainNameAliasTypes, ApplicationTaskAccessLevel.Delete)]
        public DeleteResponseModel Delete(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var nameAliasTypes = _dbContext.Set<NameAliasType>().
                                           Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();

                if (!nameAliasTypes.Any()) throw new HttpResponseException(HttpStatusCode.NotFound);

                response.InUseIds = new List<int>();

                foreach (var nameAliasType in nameAliasTypes)
                {
                    try
                    {
                        if (AliasTypeInUse(nameAliasType.Id))
                        {
                            response.InUseIds.Add(nameAliasType.Id);
                        }
                        else
                        {
                            _dbContext.Set<NameAliasType>().Remove(nameAliasType);
                            _dbContext.SaveChanges();
                        }
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(nameAliasType.Id);
                        }
                        _dbContext.Detach(nameAliasType);
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

        internal bool AliasTypeInUse(int id)
        {
            return _dbContext.Set<NameAlias>()
                             .Any(_ => _.AliasType.Id == id);
        }

        IEnumerable<ValidationError> Validate(NameAliasTypeModel aliasType, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(aliasType))
                yield return validationError;

            foreach (var vr in CheckForErrors(aliasType, operation)) yield return vr;
        }

        IEnumerable<ValidationError> CheckForErrors(NameAliasTypeModel aliasType, Operation operation)
        {
            var all = _dbContext.Set<NameAliasType>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != aliasType.Id))
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var others = operation == Operation.Update ? all.Where(_ => _.Id != aliasType.Id).ToArray() : all;
            if (others.Any(_ => _.Code.IgnoreCaseEquals(aliasType.Code)))
            {
                yield return ValidationErrors.NotUnique(string.Format(Resources.ErrorDuplicateNameAliasType, aliasType.Code), "type");
            }

            if (others.Any(_ => _.Description.IgnoreCaseEquals(aliasType.Description)))
            {
                yield return ValidationErrors.NotUnique(string.Format(Resources.ErrorDuplicateNameAliasDesc, aliasType.Description), "description");
            }
        }
    }

    public class NameAliasTypeModel
    {
        public int Id { get; set; }

        [Required]
        [MaxLength(2)]
        public string Code { get; set; }

        [Required]
        [MaxLength(30)]
        public string Description { get; set; }

        public bool? IsUnique { get; set; }

    }
}
