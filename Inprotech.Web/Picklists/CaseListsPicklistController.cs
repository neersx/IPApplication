using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Components.Security;
using Microsoft.Build.Framework;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/CaseLists")]
    public class CaseListsPicklistController : ApiController
    {
        readonly ICaseListMaintenance _caseListMaintenance;
        readonly ISecurityContext _securityContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public CaseListsPicklistController(ISecurityContext securityContext, ICaseListMaintenance caseListMaintenance, ITaskSecurityProvider taskSecurityProvider)
        {
            _securityContext = securityContext;
            _caseListMaintenance = caseListMaintenance;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(CaseList))]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(CaseList), ApplicationTask.MaintainCaseList)]
        [PicklistMaintainabilityActions(allowDuplicate: false)]
        public PagedResults Get([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                CommonQueryParameters queryParameters
                                    = null, string search = "", string mode = "all")
        {
            CheckForRequiredPermissions(mode);

            var result = _caseListMaintenance.GetCaseLists();

            if (!string.IsNullOrWhiteSpace(search))
            {
                result = result.Where(_ => _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) >= 0 ||
                                           _.Description?.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) >= 0).ToArray();
            }

            var queryParam = queryParameters ?? new CommonQueryParameters();
            if (mode == "maintenance" && result != null)
            {
                queryParam.Take = result.Count();
            }
            return Helpers.GetPagedResults(result, queryParam,
                                           x => x.Value, x => x.Description, search);
        }

        [HttpGet]
        [Route("{id}")]
        [PicklistPayload(typeof(CaseList), ApplicationTask.MaintainCaseList)]
        public CaseList CaseList(int id)
        {
            return _caseListMaintenance.GetCaseList(id);
        }

        [HttpPost]
        [Route("")]
        public dynamic Save(CaseList caseList)
        {
            return _caseListMaintenance.Save(caseList);
        }

        [HttpPut]
        [Route("{id}")]
        public dynamic Update(int id, CaseList caseList)
        {
            return _caseListMaintenance.Update(id, caseList);
        }

        [HttpDelete]
        [Route("{id}")]
        public dynamic Delete(int id)
        {
            return _caseListMaintenance.Delete(id);
        }

        [HttpPost]
        [Route("deleteList")]
        [RequiresAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Execute)]
        [RequiresAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Delete)]
        public dynamic DeleteList(List<int> caseListIds)
        {
            return _caseListMaintenance.Delete(caseListIds);
        }

        [HttpGet]
        [Route("viewdata")]
        public dynamic GetViewData()
        {
            return new
            {
                Permissions = new
                {
                    CanInsertCaseList = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Execute) || _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Create),
                    CanUpdateCaseList = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Execute) || _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Modify),
                    CanDeleteCaseList = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Execute) || _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Delete)
                }
            };
        }

        [HttpPost]
        [Route("cases")]
        public PagedResults GetCaseListItems(CaseListItemRequest request)
        {
            if (_securityContext.User.IsExternalUser)
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }

            var result = _caseListMaintenance.GetCases(request.CaseKeys, request.PrimeCaseKey, request.NewlyAddedCaseKeys);

            return Helpers.GetPagedResults(result,
                                           request.QueryParameters ?? new CommonQueryParameters(),
                                           x => x.CaseKey.ToString(), x => x.CaseRef, string.Empty);
        }

        void CheckForRequiredPermissions(string mode)
        {
            if (_securityContext.User.IsExternalUser || (mode == "maintenance"
                                                         && !_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Execute)
                                                         && !_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Create)
                                                         && !_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Modify)
                                                         && !_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Delete)))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }
        }
    }

    public class CaseList
    {
        [PicklistKey]
        public int Key { get; set; }

        [DisplayName("caseList")]
        [DisplayOrder(0)]
        [Required]
        public string Value { get; set; }

        [DisplayName("description")]
        [DisplayOrder(1)]
        public string Description { get; set; }

        public Case PrimeCase { get; set; }

        [DisplayName("primeCaseName")]
        [DisplayOrder(2)]
        public string PrimeCaseName => PrimeCase?.Value;

        public IEnumerable<int> CaseKeys { get; set; }
    }

    public class CaseListItem
    {
        public int CaseKey { get; set; }

        public string CaseRef { get; set; }

        public string OfficialNumber { get; set; }

        public string Title { get; set; }

        public bool IsPrimeCase { get; set; }

        public bool IsNewlyAddedCase { get; set; }
    }

    public class CaseListItemRequest
    {
        public CommonQueryParameters QueryParameters { get; set; }
        public IEnumerable<int> CaseKeys { get; set; }
        public IEnumerable<int> NewlyAddedCaseKeys { get; set; }

        public int? PrimeCaseKey { get; set; }
    }
}