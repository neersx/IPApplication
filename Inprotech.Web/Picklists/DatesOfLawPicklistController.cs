using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Persistence;
using EntityModel = InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/datesoflaw")]
    public class DatesOfLawPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IFormatDateOfLaw _formatDateOfLaw;
        readonly IDateOfLawPicklistMaintenance _dateOfLawPicklistMaintenance;

        readonly CommonQueryParameters _defaultQueryParameters;

        public DatesOfLawPicklistController(IDbContext dbContext, IDateOfLawPicklistMaintenance dateOfLawPicklistMaintenance, IFormatDateOfLaw formatDateOfLaw)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _formatDateOfLaw = formatDateOfLaw ?? throw new ArgumentNullException(nameof(formatDateOfLaw));
            _dateOfLawPicklistMaintenance = dateOfLawPicklistMaintenance ?? throw new ArgumentNullException(nameof(dateOfLawPicklistMaintenance));

            _defaultQueryParameters = new CommonQueryParameters { SortBy = "Date" };
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(DateOfLaw), ApplicationTask.MaintainWorkflowRules)]
        [PicklistMaintainabilityActions(allowDuplicate: false)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(DateOfLaw), ApplicationTask.MaintainWorkflowRules, true)]
        public PagedResults DatesOfLaw(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                = null, string search = "", string jurisdiction = "", string propertyType = "")
        {
            var extendedQueryParams = _defaultQueryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            if (extendedQueryParams.SortBy != null &&
                extendedQueryParams.SortBy.Equals("dateOfLawFormatted", StringComparison.InvariantCultureIgnoreCase))
            {
                extendedQueryParams.SortBy = "Date";
            }

            if (string.IsNullOrEmpty(jurisdiction) || string.IsNullOrEmpty(propertyType))
                return Helpers.GetPagedResults(new DateOfLaw[0],
                                               extendedQueryParams,
                                               x => x.Key.ToString(), x => x.Value, search);

            var jurisdictions = jurisdiction.Split(',');
            var datesofLaw = _dbContext.Set<EntityModel.DateOfLaw>()
                                        .Where(dol => jurisdictions.Contains(dol.CountryId) && dol.PropertyTypeId == propertyType)
                                        .Select(_ => new DateOfLaw { Date = _.Date, Key = _.Id }).AsEnumerable()
                                        .DistinctBy(x => x.Date).ToArray();

            var result = datesofLaw.Select(d => new DateOfLaw
            {
                Key = d.Key,
                Code = _formatDateOfLaw.AsId(d.Date),
                Value = _formatDateOfLaw.Format(d.Date),
                Date = d.Date
            });

            if (string.IsNullOrEmpty(search))
            {
                return Helpers.GetPagedResults(result,
                                               extendedQueryParams,
                                               x => x.Key.ToString(), x => x.Value, search);
            }

            result = result.Where(r => r.Value.IgnoreCaseContains(search));

            return Helpers.GetPagedResults(result,
                                           extendedQueryParams,
                                           x => x.Key.ToString(), x => x.Value, search);
        }

        [HttpGet]
        [Route("{id}")]
        [PicklistPayload(typeof(DateOfLaw), ApplicationTask.MaintainWorkflowRules, true)]
        public dynamic DateOfLaw(int id)
        {
            var defaultDateOfLaw = _dbContext.Set<EntityModel.DateOfLaw>().SingleOrDefault(dol => dol.Id == id);

            if (defaultDateOfLaw == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            return defaultDateOfLaw.DateOfLawModel(_dbContext, _formatDateOfLaw);
        }

        [HttpDelete]
        [Route("{dateOfLawId}")]
        [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
        public dynamic Delete(int dateOfLawId)
        {
            return _dateOfLawPicklistMaintenance.Delete(dateOfLawId);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
        public dynamic Add(DateOfLawSaveModel dateOfLawSaveModel)
        {
            return _dateOfLawPicklistMaintenance.Save(dateOfLawSaveModel.DefaultDateOfLaw, dateOfLawSaveModel.AffectedActions, Operation.Add);
        }

        [HttpPut]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
        public dynamic Update(int id, DateOfLawSaveModel dateOfLawSaveModel)
        {
            return _dateOfLawPicklistMaintenance.Save(dateOfLawSaveModel.DefaultDateOfLaw, dateOfLawSaveModel.AffectedActions, Operation.Update);
        }
    }

    public class DateOfLaw
    {
        [PicklistKey]
        public int Key { get; set; }

        public string Code { get; set; }

        [PicklistDescription(@"DateOfLaw")]
        [DisplayOrder(0)]
        public string Value { get; set; }

        public DateTime Date { get; set; }
    }

    public class DefaultDateOfLaw
    {
        public DefaultDateOfLaw()
        {
        }

        public DefaultDateOfLaw(EntityModel.DateOfLaw dateOfLawEntry, IFormatDateOfLaw formatDateOfLaw)
        {
            Key = dateOfLawEntry.Id;
            Date = dateOfLawEntry.Date;
            Value = formatDateOfLaw.Format(dateOfLawEntry.Date);
            Jurisdiction = new Jurisdiction
            {
                Value = dateOfLawEntry.Country.Name,
                Code = dateOfLawEntry.CountryId
            };
            PropertyType = new PropertyType
            {
                Code = dateOfLawEntry.PropertyType.Code,
                Key = dateOfLawEntry.PropertyType.Id,
                Value = dateOfLawEntry.PropertyType.Name
            };
            DefaultEventForLaw = dateOfLawEntry.LawEvent != null
                ? new Event
                {
                    Code = dateOfLawEntry.LawEvent.Code,
                    Value = dateOfLawEntry.LawEvent.Description,
                    Key = dateOfLawEntry.LawEvent.Id
                }
                : null;
            DefaultRetrospectiveEvent = dateOfLawEntry.RetroEvent != null
                ? new Event
                {
                    Code = dateOfLawEntry.RetroEvent.Code,
                    Value = dateOfLawEntry.RetroEvent.Description,
                    Key = dateOfLawEntry.RetroEvent.Id
                }
                : null;
        }

        [Required]
        public int Key { get; set; }

        [Required]
        public Event DefaultEventForLaw { get; set; }
       
        public Event DefaultRetrospectiveEvent { get; set; }

        [Required]
        public Jurisdiction Jurisdiction { get; set; }

        [Required]
        public PropertyType PropertyType { get; set; }

        [Required]
        public DateTime Date { get; set; }

        public string Value { get; set; }
    }

    public class AffectedActions : DefaultDateOfLaw
    {
        public AffectedActions()
        {
            
        }

        public AffectedActions(EntityModel.DateOfLaw dateOfLawEntry, IFormatDateOfLaw formatDateOfLaw)
                        : base(dateOfLawEntry, formatDateOfLaw)
        {
            RetrospectiveAction = dateOfLawEntry.RetroAction == null
                ? null
                : new Action
                {
                    Code = dateOfLawEntry.RetroAction.Code,
                    Key = dateOfLawEntry.RetroAction.Id,
                    Value = dateOfLawEntry.RetroAction.Name
                };
        }

        public Action RetrospectiveAction { get; set; }
    }

    public class DateOfLawModel
    {
        public DefaultDateOfLaw DefaultDateOfLaw { get; set; }

        public IEnumerable<AffectedActions> AffectedActions { get; set; }
    }

    public class DateOfLawSaveModel
    {
        public DefaultDateOfLaw DefaultDateOfLaw { get; set; }

        public Delta<AffectedActions> AffectedActions { get; set; }
    }

    public static class DateOfLawModelExt
    {
        public static dynamic DateOfLawModel(this EntityModel.DateOfLaw dateOfLaw, IDbContext dbContext, IFormatDateOfLaw formatDateOfLaw)
        {
            var allEntries = dbContext.Set<EntityModel.DateOfLaw>()
                                    .Where(d => d.CountryId == dateOfLaw.CountryId
                                             && d.PropertyTypeId == dateOfLaw.PropertyTypeId
                                             && d.Date == dateOfLaw.Date);

            var count = allEntries.Count(_ => _.RetroAction == null);

            if (count == 0)
            {
                return ValidationErrors.SetError("dateOfLaw", "picklist.dateoflaw.invalidDateOfLaw").AsErrorResponse();
            }

            var defaultDateOfLaw = new DefaultDateOfLaw(allEntries.Where(_ => _.RetroAction == null).OrderBy(_=> _.SequenceNo).First(), formatDateOfLaw);
            return new DateOfLawModel
            {
                DefaultDateOfLaw = defaultDateOfLaw,
                AffectedActions = allEntries.Where(_ => _.Id != defaultDateOfLaw.Key).ToArray()
                                                .Select(_ => new AffectedActions(_ , formatDateOfLaw))
                                                .OrderBy(_ => _.RetrospectiveAction?.Value)
                                                .ThenBy(_ => _.DefaultEventForLaw.Value)
                                                .ThenBy(_ => _.DefaultRetrospectiveEvent?.Value)
                
            };
        }
    }
}