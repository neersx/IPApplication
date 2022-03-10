using System.Collections.Generic;
using System.Linq;
using AutoMapper;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Accounting;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class DebtorSplitUpdaterFacts : FactBase
    {
        [Fact]
        public void PurgeAllSplits()
        {
            var diary = new Diary {EntryNo = 1, DebtorSplits = new List<DebtorSplitDiary> {new DebtorSplitDiary {LocalValue = 10}.In(Db), new DebtorSplitDiary {LocalValue = 11}.In(Db)}}.In(Db);

            Assert.Equal(2, Db.Set<DebtorSplitDiary>().Count());
            var f = new DebtorSplitUpdaterFixture(Db);
            f.Subject.PurgeSplits(diary);
            Db.SaveChanges();

            Assert.Equal(0, Db.Set<DebtorSplitDiary>().Count());
        }

        [Fact]
        public void UpdateAllSplits()
        {
            var diary = new Diary {EntryNo = 1, EmployeeNo = 1, DebtorSplits = new List<DebtorSplitDiary> {new DebtorSplitDiary {LocalValue = 10}.In(Db), new DebtorSplitDiary {LocalValue = 11}.In(Db)}}.In(Db);

            Assert.Equal(2, Db.Set<DebtorSplitDiary>().Count());
            var f = new DebtorSplitUpdaterFixture(Db);
            f.Subject.UpdateSplits(diary, new[] {new DebtorSplit {LocalValue = 3, EntryNo = diary.EntryNo}, new DebtorSplit {LocalValue = 2}, new DebtorSplit {LocalValue = 1}});
            Db.SaveChanges();

            var newSplits = Db.Set<Diary>().First().DebtorSplits; 
            Assert.True(newSplits.Any(_ => _.LocalValue == 1));
            Assert.True(newSplits.Any(_ => _.LocalValue == 2));
            Assert.True(newSplits.Any(_ => _.LocalValue == 3));

            Assert.False(newSplits.Any(_ => _.LocalValue == 10));
            Assert.False(newSplits.Any(_ => _.LocalValue == 11));
        }
    }

    public class DebtorSplitUpdaterFixture : IFixture<IDebtorSplitUpdater>
    {
        public DebtorSplitUpdaterFixture(InMemoryDbContext db)
        {
            var m = new Mapper(new MapperConfiguration(cfg =>
            {
                cfg.AddProfile(new AccountingProfile());
                cfg.CreateMissingTypeMaps = true;
            }));
            Mapper = m.DefaultContext.Mapper.DefaultContext.Mapper;

            Subject = new DebtorSplitUpdater(db, Mapper);
        }

        public IMapper Mapper { get; }
        public IDebtorSplitUpdater Subject { get; }
    }
}