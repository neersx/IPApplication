using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Web.CaseSupportData
{
    public interface IActionEventNotes
    {
        IEnumerable<string> ActionIdsWithEventNotes(int caseId);
    }

    public class ActionEventNotes : IActionEventNotes
    {
        readonly IDbContext _dbContext;

        public ActionEventNotes(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<string> ActionIdsWithEventNotes(int caseId)
        {
            var openActions = _dbContext.Set<OpenAction>().Where(_ => _.CaseId == caseId);
           
            var eventCriteriaNumbers = (from et in _dbContext.Set<CaseEventText>()
                             where et.CaseId == caseId 
                             join validEvent in _dbContext.Set<ValidEvent>() on et.EventId equals validEvent.EventId 
                                select validEvent.CriteriaId).Distinct();

            return from a in openActions
                    where a.CriteriaId != null && eventCriteriaNumbers.Contains(a.CriteriaId.Value)
                    select a.ActionId;
        }
    }
}
