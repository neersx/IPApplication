using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Classic
{
    public interface IDocumentGenerator
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        void QueueDocument(
            Case @case,
            DataEntryTask dataEntryTask,
            IEnumerable<Document> documents,
            DateTime requestTime);

        void QueueChecklistQuestionDocument(Case @case, short checklistType, int checklistCriteria, short? questionId, Document document);
        Task QueueDocument(int copyFromActivityId, Action<CaseActivityRequest, CaseActivityRequest> afterCopy);
    }

    public class DocumentGenerator : IDocumentGenerator
    {
        readonly IDbContext _dbContext;
        readonly IActivityRequestHistoryMapper _mapper;
        readonly Func<DateTime> _now;
        readonly ISecurityContext _securityContext;

        public DocumentGenerator(IDbContext dbContext, ISecurityContext securityContext, Func<DateTime> now, IActivityRequestHistoryMapper mapper)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _now = now;
            _mapper = mapper;
        }

        public void QueueDocument(
            Case @case,
            DataEntryTask dataEntryTask,
            IEnumerable<Document> documents,
            DateTime requestTime)
        {
            if (@case == null) throw new ArgumentNullException("case");
            if (dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");
            if (documents == null) throw new ArgumentNullException("documents");

            var hasPrimaryCase = _dbContext.Set<CaseListMember>().Any(cl => cl.CaseId == @case.Id && cl.IsPrimeCase);

            foreach (var document in documents)
            {
                if (document.IsForPrimeCasesOnly && !hasPrimaryCase)
                {
                    continue;
                }

                @case.PendingRequests.Add(
                                          new CaseActivityRequest(@case, requestTime, _securityContext.User.UserName)
                                          {
                                              ActionId = dataEntryTask.Criteria.Action.Code,
                                              LetterNo = document.Id,
                                              HoldFlag = document.HoldFlag,
                                              LetterDate = requestTime,
                                              DeliveryMethodId = document.DeliveryMethodId,
                                              ActivityType = (short?) TableTypes.SystemActivity,
                                              ActivityCode = KnownSystemActivity.Letters,
                                              Processed = 0,
                                              ProgramId = KnownPrograms.WebApps
                                          });
            }
        }

        public async Task QueueDocument(int copyFromActivityId, Action<CaseActivityRequest, CaseActivityRequest> afterCopy)
        {
            if (afterCopy == null) throw new ArgumentNullException(nameof(afterCopy));

            var copyFromRequest = await _dbContext.Set<CaseActivityRequest>()
                                                  .SingleAsync(_ => _.Id == copyFromActivityId);

            var newRequest = _mapper.CopyAsNewRequest(copyFromRequest,
                                                      (current, next) =>
                                                      {
                                                          afterCopy(current, next);

                                                          next.HoldFlag = 0;
                                                          next.Processed = 0;
                                                          next.SystemMessage = null;
                                                      });

            _dbContext.Set<CaseActivityRequest>().Add(newRequest);
        }

        public void QueueChecklistQuestionDocument(Case @case, short checklistType, int checklistCriteria, short? questionId, Document document)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (document == null) throw new ArgumentNullException(nameof(document));

            var hasPrimaryCase = @case.CaseListMemberships.Any(cl => cl.CaseId == @case.Id && cl.IsPrimeCase);

            if (document.IsForPrimeCasesOnly && !hasPrimaryCase)
            {
                return;
            }

            @case.PendingRequests.Add(new CaseActivityRequest(@case, _now(), _securityContext.User.UserName)
            {
                ProgramId = KnownPrograms.WebApps,
                LetterNo = document.Id,
                HoldFlag = document.HoldFlag,
                LetterDate = _now(),
                QuestionId = questionId,
                DeliveryMethodId = document.DeliveryMethodId,
                ActivityType = (short?) TableTypes.SystemActivity,
                ActivityCode = KnownSystemActivity.Letters,
                ChecklistType = checklistType,
                Processed = 0,
                TransactionFlag = 0
            });
        }
    }
}