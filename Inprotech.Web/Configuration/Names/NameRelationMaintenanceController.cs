using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Extentions;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using ValidationError = Inprotech.Infrastructure.Validations.ValidationError;

namespace Inprotech.Web.Configuration.Names
{
    [Authorize]
    [RoutePrefix("api/configuration/names/namerelation")]
    public class NameRelationMaintenanceController : ApiController
    {
        readonly ILicenseSecurityProvider _licenseSecurityProvider;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        static readonly CommonQueryParameters DefaultQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "RelationshipCode",
                SortDir = "asc"
            });
        
        bool HasCrmLisences => _licenseSecurityProvider?.IsLicensedForModules(new List<LicensedModule> { LicensedModule.CrmWorkBench, LicensedModule.MarketingModule }) ?? false;

        public NameRelationMaintenanceController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ILicenseSecurityProvider licenseSecurityProvider)
        {
            _licenseSecurityProvider = licenseSecurityProvider;
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
           
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainNameRelationshipCode, ApplicationTaskAccessLevel.None)]
        public dynamic ViewData()
        {
            return new
            {
                EthicalWallOptions= KnownEthicalWallOptions.GetValues()
            };
        }

        [HttpGet]
        [Route("search")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainNameRelationshipCode, ApplicationTaskAccessLevel.None)]
        public dynamic Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] NameRelationSearchOptions searchOptions,
                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);
            var results = _dbContext.Set<NameRelation>().ToList().Select(ConvertToNameRelationModel).AsEnumerable();

            if (!string.IsNullOrEmpty(searchOptions?.Text))
                results = results.Where(x =>
                                            x.RelationshipCode.Equals(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase)
                                            || x.RelationshipDescription.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1);

            return results.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
        }

        [HttpGet]   
        [Route("{id}")]
        [NoEnrichment]
        public dynamic GetNameRelation(int id)
        {
            var namerelation = _dbContext.Set<NameRelation>().SingleOrDefault(_ => _.Id == id);

            if (namerelation == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            return ConvertToNameRelationModel(namerelation);
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainNameRelationshipCode, ApplicationTaskAccessLevel.Create)]
        public dynamic Save(NameRelationsModel nameRelationModel)
        {
            if (nameRelationModel == null) throw new ArgumentNullException(nameof(nameRelationModel));

            var validationErrors = Validate(nameRelationModel, Operation.Add).ToArray();

            if (!validationErrors.Any())
            {

                var namerelation = ConvertBackToNameRelation(nameRelationModel);
                _dbContext.Set<NameRelation>().Add(namerelation);
                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    UpdatedId = namerelation.Id
                };
            }

            return validationErrors.AsErrorResponse();
        }

        [HttpPut]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainNameRelationshipCode, ApplicationTaskAccessLevel.Modify)]
        public dynamic Update(int id, NameRelationsModel nameRelationModel)
        {
            if (nameRelationModel == null) throw new ArgumentNullException(nameof(nameRelationModel));

            var validationErrors = Validate(nameRelationModel, Operation.Update).ToArray();

            if (!validationErrors.Any())
            {
                var entityToUpdate = _dbContext.Set<NameRelation>().FirstOrDefault(_ => _.Id == id);

                if (entityToUpdate == null)
                    throw new HttpResponseException(HttpStatusCode.NotFound);

                var model = ConvertBackToNameRelation(nameRelationModel);

                entityToUpdate.RelationDescription = model.RelationDescription;
                entityToUpdate.ReverseDescription = model.ReverseDescription;
                entityToUpdate.UsedByNameType = model.UsedByNameType;
                entityToUpdate.CrmOnly = model.CrmOnly;
                entityToUpdate.EthicalWall = model.EthicalWall;

                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    UpdatedId = entityToUpdate.Id
                };
            }

            return validationErrors.AsErrorResponse();
        }

        [HttpPost]
        [Route("delete")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainNameRelationshipCode, ApplicationTaskAccessLevel.Delete)]
        public DeleteResponseModel Delete(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var nameRelations = _dbContext.Set<NameRelation>().
                                            Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();

                if (!nameRelations.Any()) throw new HttpResponseException(HttpStatusCode.NotFound);
                response.InUseIds = new List<int>();

                foreach (var model in nameRelations)
                {
                    try
                    {
                        _dbContext.Set<NameRelation>().Remove(model);
                        _dbContext.SaveChanges();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(model.Id);
                        }
                        _dbContext.Detach(model);
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

        IEnumerable<ValidationError> Validate(NameRelationsModel nameRelationModel, Operation operation)
        {

            foreach (var validationError in CommonValidations.Validate(nameRelationModel))
                yield return validationError;

            var all = _dbContext.Set<NameRelation>().ToArray();

            var others = operation == Operation.Update ? all.Where(_ => _.Id != nameRelationModel.Id).ToArray() : all;

            if (others.Any(_ => _.RelationshipCode.IgnoreCaseEquals(nameRelationModel.RelationshipCode)))
            {
                yield return ValidationErrors.NotUnique(string.Format(ConfigurationResources.ErrorDuplicateNameRelationshipCode, nameRelationModel.RelationshipCode), "relationshipCode");
            }

            if (others.Any(_ => _.RelationDescription.IgnoreCaseEquals(nameRelationModel.RelationshipDescription)))
            {
                yield return ValidationErrors.NotUnique(string.Format(ConfigurationResources.ErrorDuplicateNameRelationshipDescription, nameRelationModel.RelationshipDescription), "relationshipDescription");
            }

            if (others.Any(_ => _.ReverseDescription.IgnoreCaseEquals(nameRelationModel.ReverseDescription)))
            {
                yield return ValidationErrors.NotUnique(string.Format(ConfigurationResources.ErrorDuplicateNameRelationshipReverseDescription, nameRelationModel.ReverseDescription), "reverseDescription");
            }

            if (!nameRelationModel.IsEmployee && !nameRelationModel.IsIndividual && !nameRelationModel.IsOrganisation)
            {
                yield return ValidationErrors.SetError("isEmployee", ConfigurationResources.NameRelationAtleastOneOptionRequired);
                yield return ValidationErrors.SetError("isIndividual", ConfigurationResources.NameRelationAtleastOneOptionRequired);
                yield return ValidationErrors.SetError("isOrganisation", ConfigurationResources.NameRelationAtleastOneOptionRequired);
            }
        }

        NameRelationsModel ConvertToNameRelationModel(NameRelation nameRelation)
        {
            if (nameRelation == null) throw new ArgumentNullException(nameof(nameRelation));
            var culture = _preferredCultureResolver.Resolve();
            return new NameRelationsModel
            {
                Id = nameRelation.Id,
                RelationshipCode = nameRelation.RelationshipCode,
                RelationshipDescription = DbFuncs.GetTranslation(nameRelation.RelationDescription, null, nameRelation.RelationDescriptionTId, culture),
                ReverseDescription = DbFuncs.GetTranslation(nameRelation.ReverseDescription, null, nameRelation.ReverseDescriptionTId, culture),
                IsCrmOnly = HasCrmLisences ? nameRelation.CrmOnly.HasValue && nameRelation.CrmOnly.Value : (bool?)null,
                IsEmployee = nameRelation.UsedAsEmployee,
                IsIndividual = nameRelation.UsedAsIndividual,
                IsOrganisation = nameRelation.UsedAsOrganisation,
                HasCrmLisences = HasCrmLisences,
                EthicalWall = nameRelation.EthicalWall.ToString(),
                EthicalWallValue = KnownEthicalWallOptions.GetValue(nameRelation.EthicalWall)
            };
        }

        NameRelation ConvertBackToNameRelation(NameRelationsModel nameRelationsModel)
        {
            var usedByNameType = 0;
            if (nameRelationsModel.IsEmployee)
                usedByNameType = usedByNameType | (int)NameRelationType.Employee;

            if (nameRelationsModel.IsIndividual)
                usedByNameType = usedByNameType | (int)NameRelationType.Individual;

            if (nameRelationsModel.IsOrganisation)
                usedByNameType = usedByNameType | (int)NameRelationType.Organisation;
            
            return new NameRelation(nameRelationsModel.RelationshipCode, nameRelationsModel.RelationshipDescription,
                                    nameRelationsModel.ReverseDescription, usedByNameType, HasCrmLisences ? nameRelationsModel.IsCrmOnly : null, Convert.ToByte(nameRelationsModel.EthicalWall)){ Id = nameRelationsModel.Id};
        }

    }

    public class NameRelationSearchOptions
    {
        public string Text { get; set; }
    }
    
}
