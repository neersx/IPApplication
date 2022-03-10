using System.Collections.Generic;
using System.Linq;
using AutoMapper;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public interface IDebtorSplitUpdater
    {
        void PurgeSplits(Diary diary);
        void UpdateSplits(Diary diary, IEnumerable<DebtorSplit> debtorSplits);
    }

    public class DebtorSplitUpdater : IDebtorSplitUpdater
    {
        readonly IDbContext _dbContext;
        readonly IMapper _mapper;

        public DebtorSplitUpdater(IDbContext dbContext, IMapper mapper)
        {
            _dbContext = dbContext;
            _mapper = mapper;
        }
        public void PurgeSplits(Diary diary)
        {
            var currentSplits = diary.DebtorSplits?.ToList();
            currentSplits?.ForEach(split => _dbContext.Set<DebtorSplitDiary>().Remove(split));
        }

        public void UpdateSplits(Diary diary, IEnumerable<DebtorSplit> debtorSplits)
        {
            PurgeSplits(diary);
           
            var debtorSplitsList = debtorSplits?.ToList();
            if (debtorSplitsList != null && debtorSplitsList.Any())
            {
                var newdebtorSplits = _mapper.Map<List<DebtorSplitDiary>>(debtorSplitsList);
                diary.DebtorSplits = new List<DebtorSplitDiary>();
                diary.DebtorSplits.AddRange(newdebtorSplits);
            }
        }
    }
}
