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
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Names
{

    [Authorize]
    [RoutePrefix("api/configuration/names/locality")]
    public class LocalityMaintenanceController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        static readonly CommonQueryParameters DefaultQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Name",
                SortDir = "asc"
            });

        public LocalityMaintenanceController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainLocality, ApplicationTaskAccessLevel.None)]
        public dynamic ViewData()
        {
            return null;
        }

        [HttpGet]
        [Route("search")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainLocality, ApplicationTaskAccessLevel.None)]
        public dynamic Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SearchOptions searchOptions,
                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            var culture = _preferredCultureResolver.Resolve();
            
            var results = _dbContext.Set<Locality>().Select(_ => new
            {
                _.Id,
                _.Code,
                Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                City = DbFuncs.GetTranslation(_.City, null, _.CityTId, culture),
                State = DbFuncs.GetTranslation(_.State.Name, null, _.State.NameTId, culture),
                Country = DbFuncs.GetTranslation(_.Country.Name, null, _.Country.NameTId, culture)
            }).AsEnumerable();

            if (!string.IsNullOrEmpty(searchOptions?.Text))
                results = results.Where(x =>
                                            x.Code.Equals(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase)
                                            || x.Name.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1);

            return results.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
        }

        [HttpGet]
        [Route("{id}")]
        [NoEnrichment]
        public dynamic GetLocality(int id)
        {
            var locality = _dbContext.Set<Locality>().Select(_ => new LocalitySaveDetails
            {
                Id = _.Id,
                Code = _.Code,
                Name = _.Name,
                City = _.City,
                Country = new Jurisdiction { Code = _.Country.Id, Value = _.Country.Name},
                State = new Picklists.State { Code = _.State.Code, Value = _.State.Name}
            }).SingleOrDefault(_ => _.Id == id);

            if (locality == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            return locality;
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainLocality, ApplicationTaskAccessLevel.Create)]
        public dynamic Save(LocalitySaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            var validationErrors = Validate(saveDetails, Operation.Add).ToArray();

            if (!validationErrors.Any())
            {
                var locality = new Locality(saveDetails.Code, saveDetails.Name, saveDetails.City)
                {
                    StateCode = saveDetails.State?.Code,
                    CountryCode = saveDetails.Country?.Code
                };

                _dbContext.Set<Locality>().Add(locality);
                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    UpdatedId = locality.Id
                };
            }

            return validationErrors.AsErrorResponse();
        }

        [HttpPut]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainLocality, ApplicationTaskAccessLevel.Modify)]
        public dynamic Update(int id, LocalitySaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            var validationErrors = Validate(saveDetails, Operation.Update).ToArray();

            if (!validationErrors.Any())
            {
                var entityToUpdate = _dbContext.Set<Locality>().FirstOrDefault(_ => _.Id == id);

                if (entityToUpdate == null)
                    throw new HttpResponseException(HttpStatusCode.NotFound);

                entityToUpdate.Name = saveDetails.Name;
                entityToUpdate.City = saveDetails.City;
                entityToUpdate.StateCode = saveDetails.State?.Code;
                entityToUpdate.CountryCode = saveDetails.Country?.Code;

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
        [RequiresAccessTo(ApplicationTask.MaintainLocality, ApplicationTaskAccessLevel.Delete)]
        public DeleteResponseModel Delete(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var localities = _dbContext.Set<Locality>().
                                                  Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();

                if(!localities.Any()) throw new HttpResponseException(HttpStatusCode.NotFound);

                response.InUseIds = new List<int>();

                foreach (var locality in localities)
                {
                    try
                    {
                        _dbContext.Set<Locality>().Remove(locality);
                        _dbContext.SaveChanges();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(locality.Id);
                        }
                        _dbContext.Detach(locality);
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

        IEnumerable<Infrastructure.Validations.ValidationError> Validate(LocalitySaveDetails locality, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(locality))
                yield return validationError;

            var all = _dbContext.Set<Locality>().ToArray();

            var others = operation == Operation.Update ? all.Where(_ => _.Id != locality.Id).ToArray() : all;

            if (others.Any(_ => _.Code.IgnoreCaseEquals(locality.Code)))
            {
                yield return ValidationErrors.NotUnique(string.Format(ConfigurationResources.ErrorDuplicateLocalityCode, locality.Code), "code");
            }
        }
    }

    public class LocalitySaveDetails
    {
        public int Id { get; set; }

        [MaxLength(5)]
        [Required]
        public string Code { get; set; }

        [MaxLength(30)]
        public string Name { get; set; }

        public string City { get; set; }

        public Jurisdiction Country { get; set; }

        public Picklists.State State { get; set; }
    }
}
