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
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using ValidationError = Inprotech.Infrastructure.Validations.ValidationError;

namespace Inprotech.Web.Configuration.Events
{

    [Authorize]
    [RoutePrefix("api/configuration/events/eventnotetypes")]

    public class EventNoteTypeMaintenanceController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        static readonly CommonQueryParameters DefaultQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Description",
                SortDir = "asc"
            });

        public EventNoteTypeMaintenanceController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainEventNoteTypes, ApplicationTaskAccessLevel.None)]
        public dynamic ViewData()
        {
            return null;
        }

        [HttpGet]
        [Route("search")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainEventNoteTypes, ApplicationTaskAccessLevel.None)]
        public dynamic Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SearchOptions searchOptions,
                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);
            var culture = _preferredCultureResolver.Resolve();
            
            var results = _dbContext.Set<EventNoteType>().ToArray().Select(_ => new
            {
                _.Id,
                Description = DbFuncs.GetTranslation(string.Empty, _.Description, _.DescriptionTId, culture),
                _.IsExternal,
                _.SharingAllowed
            }).AsEnumerable();

            if (!string.IsNullOrEmpty(searchOptions?.Text))
                results = results.Where(x => x.Description.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1);

            return results.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
        }

        [HttpGet]
        [Route("{id}")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainEventNoteTypes, ApplicationTaskAccessLevel.None)]
        public dynamic GetEventNoteType(string id)
        {
            var selectedEventNoteType = _dbContext.Set<EventNoteType>().SingleOrDefault(_ => Equals(_.Id.ToString(), id));
            if (selectedEventNoteType == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            return new EventNoteTypeModel
            {
                Id = selectedEventNoteType.Id,
                Description = selectedEventNoteType.Description,
                IsExternal = selectedEventNoteType.IsExternal,
                SharingAllowed = selectedEventNoteType.SharingAllowed
            };
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainEventNoteTypes, ApplicationTaskAccessLevel.Create)]
        public dynamic Save(EventNoteTypeModel saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            var validationErrors = Validate(saveDetails, Operation.Add).ToArray();
            if (validationErrors.Any()) return validationErrors.AsErrorResponse();
            var eventNoteType = new EventNoteType(saveDetails.Description, saveDetails.IsExternal, saveDetails.SharingAllowed ?? false);

            _dbContext.Set<EventNoteType>().Add(eventNoteType);
            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedId = eventNoteType.Id
            };
        }

        [HttpPut]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainEventNoteTypes, ApplicationTaskAccessLevel.Modify)]
        public dynamic Update(short id, EventNoteTypeModel saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));
            var validationErrors = Validate(saveDetails, Operation.Update).ToArray();
            if (!validationErrors.Any())
            {
                var entityToUpdate = _dbContext.Set<EventNoteType>().First(_ => _.Id == id);

                entityToUpdate.Description = saveDetails.Description;
                entityToUpdate.IsExternal = saveDetails.IsExternal;
                entityToUpdate.SharingAllowed = saveDetails.SharingAllowed;

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
        [RequiresAccessTo(ApplicationTask.MaintainEventNoteTypes, ApplicationTaskAccessLevel.Delete)]
        public DeleteResponseModel Delete(EventNoteTypeDeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var eventNoteTypes = _dbContext.Set<EventNoteType>().
                                           Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();

                if (!eventNoteTypes.Any()) throw new HttpResponseException(HttpStatusCode.NotFound);

                response.InUseIds = new List<int>();

                foreach (var eventNoteType in eventNoteTypes)
                {
                    try
                    {
                        if (IsInUse(eventNoteType.Id))
                        {
                            response.InUseIds.Add(eventNoteType.Id);
                        }
                        else
                        {
                            _dbContext.Set<EventNoteType>().Remove(eventNoteType);
                            _dbContext.SaveChanges();
                        }
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(eventNoteType.Id);
                        }
                        _dbContext.Detach(eventNoteType);
                    }
                }

                txScope.Complete();

                if (response.InUseIds.Any())
                {
                    response.HasError = true;
                    response.Message = ConfigurationResources.InUseErrorMessage;
                    return response;
                }
                return response;
            }
        }

        bool IsInUse(short eventNoteTypeId)
        {
            if (_dbContext.Set<EventText>().Any(et => et.EventNoteType.Id == eventNoteTypeId))
                return true;

            if(_dbContext.Set<SettingValues>().Any(setting => setting.SettingId == KnownSettingIds.DefaultEventNoteType
                                                               && setting.IntegerValue == eventNoteTypeId))
                return true;

            return false;
        }

        IEnumerable<ValidationError> Validate(EventNoteTypeModel eventNoteType, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(eventNoteType))
                yield return validationError;

            foreach (var vr in CheckForErrors(eventNoteType, operation)) yield return vr;
        }

        IEnumerable<ValidationError> CheckForErrors(EventNoteTypeModel eventNoteType, Operation operation)
        {
            var all = _dbContext.Set<EventNoteType>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != eventNoteType.Id))
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var others = operation == Operation.Update ? all.Where(_ => _.Description != eventNoteType.Description).ToArray() : all;
            if (others.Any(_ => _.Description.IgnoreCaseEquals(eventNoteType.Description)))
            {
                yield return ValidationErrors.NotUnique(string.Format(Resources.ErrorDuplicateEventNoteTypeCode, eventNoteType.Description), "description");
            }
        }
    }

    public class EventNoteTypeModel
    {
        public short Id { get; set; }
        [Required]
        [MaxLength(250)]
        public string Description { get; set; }
        public bool IsExternal { get; set; }
        public bool? SharingAllowed { get; set; }

    }

    public class EventNoteTypeDeleteRequestModel
    {
        public List<short> Ids { get; set; }
    }
 }
