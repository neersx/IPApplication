using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Updaters
{
    public interface IReorderCaseImageSequenceNumbers
    {
        void Reorder(int caseId);
    }

    public class CaseImageSequenceNumberReorderer : IReorderCaseImageSequenceNumbers
    {
        readonly IDbContext _dbContext;

        public CaseImageSequenceNumberReorderer(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public void Reorder(int caseId)
        {
            var currentSequence = (short)0;

            foreach (var caseImage in
                    _dbContext.Set<CaseImage>().Where(_ => _.CaseId == caseId).OrderBy(_ => _.ImageSequence))
            {
                caseImage.ImageSequence = currentSequence;
                currentSequence += 1;
            }
        }
    }
}
