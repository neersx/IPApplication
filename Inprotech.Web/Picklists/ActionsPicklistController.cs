using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.ValidCombinations;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/actions")]
    public class ActionsPicklistController : ApiController
    {
        readonly IActions _actions;
        readonly CommonQueryParameters _queryParameters;
        readonly IActionsPicklistMaintenance _actionsPicklistMaintenance;
        readonly IValidActions _validActions;

        public ActionsPicklistController(IActions actions, IActionsPicklistMaintenance actionsPicklistMaintenance, IValidActions validActions)
        {
            _actions = actions;
            _actionsPicklistMaintenance = actionsPicklistMaintenance;
            _validActions= validActions;
            _queryParameters = new CommonQueryParameters {SortBy = "Value"};
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof (Action),ApplicationTask.MaintainValidCombinations, true)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof (Action),ApplicationTask.MaintainValidCombinations, true)]
        public PagedResults Actions(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                = null, string search = "", string jurisdiction = "", string propertyType = "", string caseType = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            return Helpers.GetPagedResults(MatchingItems(search, jurisdiction, propertyType, caseType),
                                           extendedQueryParams,
                                           x => x.Code, x => x.Value, search);
        }

        [HttpGet]
        [Route("{actionId}")]
        [PicklistPayload(typeof(Action), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic Action(int actionId)
        {
            // note: .key and .code store diffierent values for actions
            var listItem = _actionsPicklistMaintenance.Get(actionId);
            return new Action(listItem.Id, listItem.Code, listItem.Name, listItem.Cycles, listItem.ActionType, listItem.ImportanceLevel, listItem.IsDefaultJurisdiction);
        }

        [HttpGet]
        [Route("{actionId}")]
        [PicklistPayload(typeof(Action), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic Action(int actionId, string validCombinationKeys, bool isDefaultJurisdiction)
        {
            // note: .key and .code store diffierent values for actions
            var validActionIdentifier = GetValidActionIdentifier(_actionsPicklistMaintenance.Get(actionId).Code, validCombinationKeys, isDefaultJurisdiction);
            var response = validActionIdentifier != null ? _validActions.GetValidAction(validActionIdentifier) : Action(actionId);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        ValidActionIdentifier GetValidActionIdentifier(string actionId, string validCombinationKeys, bool isDefaultJurisdiction)
        {
            if (string.IsNullOrEmpty(validCombinationKeys)) return null;

            var vai = JsonConvert.DeserializeObject<ValidCombinationKeys>(validCombinationKeys);
            if (isDefaultJurisdiction)
            {
                vai.Jurisdiction = KnownValues.DefaultCountryCode;
            }
            if (!string.IsNullOrEmpty(vai.CaseType) && !string.IsNullOrEmpty(vai.PropertyType) && !string.IsNullOrEmpty(vai.Jurisdiction))
                return new ValidActionIdentifier(vai.Jurisdiction, vai.PropertyType, vai.CaseType, actionId);

            return null;
        }

        [HttpPut]
        [Route("{actionId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(int actionId,[FromBody] JObject actionSaveData)
        {
            if (actionSaveData == null) throw new ArgumentNullException(nameof(actionSaveData));

            var response = actionSaveData["validDescription"] != null ? _validActions.Update(actionSaveData.ToObject<ActionSaveDetails>()) 
                : _actionsPicklistMaintenance.Save(actionSaveData.ToObject<Action>(), Operation.Update);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic AddOrDuplicate([FromBody] JObject actionSaveData)
        {
            if (actionSaveData == null) throw new ArgumentNullException(nameof(actionSaveData));

            if (actionSaveData["validDescription"] == null)
                return _actionsPicklistMaintenance.Save(actionSaveData.ToObject<Action>(), Operation.Add);
            
            var response = _validActions.Save(actionSaveData.ToObject<ActionSaveDetails>());
            return response.Result != "Error" ? response : response.AsErrorResponse();
        }

        [HttpDelete]
        [Route("{actionId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(int actionId)
        {
            return _actionsPicklistMaintenance.Delete(actionId);
        }
        
        [HttpDelete]
        [Route("{actionId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(int actionId, string deleteData)
        {
            var data = JsonConvert.DeserializeObject<JObject>(deleteData); 
            if(data?["validCombinationKeys"] == null) return Delete(actionId);

            var validActionIdentifier = GetValidActionIdentifier(_actionsPicklistMaintenance.Get(actionId).Code, data["validCombinationKeys"].ToString(),bool.Parse(data["isDefaultJurisdiction"].ToString()));
            var response = _validActions.Delete(new[] {validActionIdentifier});
            if (response == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            return response.HasError ? KnownSqlErrors.CannotDelete.AsHandled() : response;
        }

        IEnumerable<Action> MatchingItems(string search = "", string jurisdiction = "", string propertyType = "",
            string caseType = "")
        {
            var actions =
                _actions.Get(jurisdiction, propertyType, caseType)
                    .Select(_ => new Action(_.Id, _.Code, _.Name, _.Cycles, _.ActionType, _.ImportanceLevel,_.IsDefaultJurisdiction));                  

            if (!string.IsNullOrEmpty(search))
            {
                actions = actions.Where(_ => _.Code.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1 ||
                                             _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
            }
            return actions;
        }

        [HttpGet]
        [Route("importancelevels")]
        public IEnumerable<dynamic> ImportanceLevels()
        {
            return _actions.ImportanceLevels();
        }
    }

    public class Action
    {
        short? _cycles;

        public Action() { }

        public Action(string code, string description)
        {
            Code = code;
            Value = description;
        }

        public Action(string code, string value, short? cycles, decimal? actionTypeFlag, string importanceLevel) : this(code, value)
        {
            Cycles = cycles;
            ActionTypeFlag = actionTypeFlag;
            UnlimitedCycles = Cycles == 9999;
            ImportanceLevel = importanceLevel;
            ActionType = actionTypeFlag != null ? (ActionType)actionTypeFlag : ActionType.Other;
        }

        public Action(int id, string code, string value, short? cycles, decimal? actionType, string importanceLevel, decimal isDefaultJurisdiction) : this(code, value, cycles, actionType, importanceLevel)
        {
            Key = id;
            IsDefaultJurisdiction = isDefaultJurisdiction == 1m;
        }

        [PicklistKey]
        public int Key { get; set; }

        [Required]
        [DisplayName(@"Code")]
        [PicklistCode]
        [MaxLength(2)]
        [DisplayOrder(1)]
        public string Code { get; set; }

        [Required]
        [MaxLength(50)]
        [PicklistDescription]
        [DisplayOrder(0)]
        public string Value { get; set; }

        [DisplayName(@"Cycles")]
        [DisplayOrder(2)]
        public short? Cycles
        {
            get => _cycles.GetValueOrDefault(1);
            set => _cycles = value;
        }
        
        public string ImportanceLevel { get; set; }

        public decimal? ActionTypeFlag { get; set; }

        public ActionType ActionType { get; set; }

        public bool IsDefaultJurisdiction { get; set; }

        public bool UnlimitedCycles { get; set; }
    }
}