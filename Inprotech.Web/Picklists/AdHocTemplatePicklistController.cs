using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/adhoctemplates")]
    public class AdHocTemplatePicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _queryParameters;

        public AdHocTemplatePicklistController(IDbContext dbContext)
        {
            _dbContext = dbContext;
            _queryParameters = new CommonQueryParameters { SortBy = "code" };
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(AdHocTemplatePicklistItem), ApplicationTask.MaintainAdHocTemplate)]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));
            var results = Data(search);

            return Helpers.GetPagedResults(results,
                                           extendedQueryParams,
                                           x => x.Code.ToString(), x => x.Message, search);
        }

        IEnumerable<AdHocTemplatePicklistItem> Data(string query)
        {
            var q = _dbContext.Set<AlertTemplate>().AsQueryable();

            if (!string.IsNullOrEmpty(query))
            {
                q = q.Where(_ => _.AlertTemplateCode.Contains(query)
                                 || _.AlertMessage.Contains(query));
            }

            var interimResult = q.ToArray().Select(_ => new AdHocTemplatePicklistItem
            {
                Code = _.AlertTemplateCode,
                Message = _.AlertMessage,
                DaysLead = _.DaysLead,
                DailyFrequency = _.DailyFrequency,
                MonthsLead = _.MonthsLead,
                MonthlyFrequency = _.MonthlyFrequency,
                StopAlert = _.StopAlert,
                DeleteAlert = _.DeleteAlert,
                RelationshipValue = _dbContext.Set<NameRelation>().SingleOrDefault(x => x.RelationshipCode == _.Relationship) != null ?
                    new
                    {
                        Key = _.Relationship,
                        Code = _.Relationship,
                        Value = _dbContext.Set<NameRelation>().SingleOrDefault(x => x.RelationshipCode == _.Relationship)?.RelationDescription
                    }
                    : null,
                CriticalFlag = _.CriticalFlag,
                EmployeeFlag = _.EmployeeFlag,
                SignatoryFlag = _.SignatoryFlag,
                AdhocResponsibleName = _dbContext.Set<InprotechKaizen.Model.Names.Name>().Any(x => x.Id == _.StaffId) ? _dbContext.Set<InprotechKaizen.Model.Names.Name>().Where(x => x.Id == _.StaffId).ToArray()
                                                                                                                                  .Select(x => new
                                                                                                                                  {
                                                                                                                                      Type = "AdhocResponsibleName",
                                                                                                                                      Key = x.Id,
                                                                                                                                      Code = x.NameCode,
                                                                                                                                      DisplayName = x.Formatted()
                                                                                                                                  }).FirstOrDefault()
                : null,
                ImportanceLevel = _dbContext.Set<Importance>().SingleOrDefault(x => x.Level == _.Importance)?.LevelNumeric,
                NameTypeValue = _dbContext.Set<NameType>().SingleOrDefault(x => x.NameTypeCode == _.NameTypeId) != null ? new
                {
                    Key = _.NameTypeId,
                    Code = _dbContext.Set<NameType>().SingleOrDefault(x => x.NameTypeCode == _.NameTypeId)?.NameTypeCode,
                    Value = _dbContext.Set<NameType>().SingleOrDefault(x => x.NameTypeCode == _.NameTypeId)?.Name
                }
                : null,
                SendElectronically = _.SendElectronically,
                EmailSubject = _.EmailSubject
            });

            return interimResult;
        }

        public class AdHocTemplatePicklistItem
        {
            [PicklistKey]
            public string Code { get; set; }

            public string Message { get; set; }
            public short? DaysLead { get; set; }
            public short? DailyFrequency { get; set; }
            public short? MonthsLead { get; set; }
            public short? MonthlyFrequency { get; set; }
            public short? StopAlert { get; set; }
            public short? DeleteAlert { get; set; }
            public dynamic ImportanceLevel { get; set; }
            public bool? EmployeeFlag { get; set; }
            public bool? SignatoryFlag { get; set; }
            public bool? CriticalFlag { get; set; }
            public bool? SendElectronically { get; set; }
            public dynamic AdhocResponsibleName { get; set; }
            public dynamic NameTypeValue { get; set; }
            public dynamic RelationshipValue { get; set; }
            public string EmailSubject { get; set; }
        }
    }
}