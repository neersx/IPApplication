using Inprotech.Infrastructure.Security;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;

namespace Inprotech.Web.Cases.AssignmentRecordal
{
    public interface IAffectedCasesSetAgent
    {
        Task<dynamic> SetAgentForAffectedCases(AffectedCasesAgentModel model);
        Task<dynamic> ClearAgentForAffectedCases(int caseKey, DeleteAffectedCaseModel affectedCaseModel);
    }
    public class AffectedCasesSetAgent : IAffectedCasesSetAgent
    {
        readonly IDbContext _dbContext;
        readonly ICaseAuthorization _caseAuthorization;
        readonly IGlobalNameChangeCommand _globalNameChangeCommand;
        readonly ISecurityContext _securityContext;
        readonly IAssignmentRecordalHelper _assignmentRecordalHelper;

        public AffectedCasesSetAgent(IDbContext dbContext, ICaseAuthorization caseAuthorization, IGlobalNameChangeCommand globalNameChangeCommand,
                                     ISecurityContext securityContext, IAssignmentRecordalHelper assignmentRecordalHelper)
        {
            _dbContext = dbContext;
            _caseAuthorization = caseAuthorization;
            _globalNameChangeCommand = globalNameChangeCommand;
            _securityContext = securityContext;
            _assignmentRecordalHelper = assignmentRecordalHelper;
        }

        public async Task<dynamic> SetAgentForAffectedCases(AffectedCasesAgentModel model)
        {
            if (model == null) throw new ArgumentNullException();

            var agentName = await _dbContext.Set<InprotechKaizen.Model.Names.Name>().FirstOrDefaultAsync(_ => _.Id == model.AgentId);
            if (agentName == null)
                throw new ArgumentException("Agent cannot not be null");

            if (model.AffectedCases == null || !model.AffectedCases.Any())
                throw new ArgumentException("No affected cases selected");

            using (var t = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var affectedCases = _assignmentRecordalHelper.GetAffectedCases(model.MainCaseId, model.AffectedCases);

                if (model.IsCaseNameSet)
                {
                    var allRelatedCases = affectedCases.Where(_ => _.RelatedCaseId.HasValue).Select(_ => _.RelatedCaseId.Value).Distinct().ToArray();
                    if (allRelatedCases.Any())
                    {
                        var listOfAuthorizedCases = (await _caseAuthorization.UpdatableCases(allRelatedCases)).ToArray();
                        if (listOfAuthorizedCases.Any())
                        {
                            await _globalNameChangeCommand.PerformGlobalNameChange(listOfAuthorizedCases, _securityContext.User.Id, KnownNameTypes.Agent, model.AgentId, 3, true, true);

                            var internalCases = affectedCases.Where(_ => _.RelatedCaseId.HasValue);
                            await _dbContext.UpdateAsync(internalCases, _ => new RecordalAffectedCase
                            {
                                AgentId = null
                            });
                        }
                    }

                    var externalCases = affectedCases.Where(_ => !_.RelatedCaseId.HasValue);
                    await _dbContext.UpdateAsync(externalCases, _ => new RecordalAffectedCase
                    {
                        AgentId = agentName.Id
                    });
                }
                else
                {
                    await _dbContext.UpdateAsync(affectedCases, _ => new RecordalAffectedCase
                    {
                        AgentId = agentName.Id
                    });
                }
                t.Complete();
            }

            return new { Result = "success" };
        }

        public async Task<dynamic> ClearAgentForAffectedCases(int caseKey, DeleteAffectedCaseModel affectedCaseModel)
        {
            if (affectedCaseModel == null) throw new ArgumentNullException();

            using (var ts = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var affectedCases = await _assignmentRecordalHelper.GetAffectedCasesToBeChanged(caseKey, affectedCaseModel);

                if (affectedCaseModel.ClearCaseNameAgent)
                {
                    var relatedCaseKeys = affectedCases.Where(_ => !_.AgentId.HasValue && _.RelatedCaseId.HasValue).Select(_ => _.RelatedCaseId.Value).Distinct().ToArray();
                    if (relatedCaseKeys.Any())
                    {
                        var listOfAuthorizedCases = (await _caseAuthorization.UpdatableCases(relatedCaseKeys)).ToArray();
                        if (listOfAuthorizedCases.Any())
                        {
                            await _globalNameChangeCommand.PerformGlobalNameChange(listOfAuthorizedCases, _securityContext.User.Id, KnownNameTypes.Agent, null, null, false, false, true);
                        }
                    }
                }

                await _dbContext.UpdateAsync(affectedCases.Where(_ => _.AgentId.HasValue), _ => new RecordalAffectedCase
                {
                    AgentId = null
                });

                ts.Complete();
            }

            return new { Result = "success" };
        }
    }

    public class AffectedCasesAgentModel
    {
        public int AgentId { get; set; }
        public bool IsCaseNameSet { get; set; }
        public int MainCaseId { get; set; }
        public IEnumerable<string> AffectedCases { get; set; }
    }
}
