using System.Collections.Generic;
using System.Threading.Tasks;
using AutoMapper;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class ValueTimeFacts
    {
        public class ForMethod : FactBase
        {
            [Fact]
            public async Task DoesNotSplitIfMultiDebtorOff()
            {
                var f = new ValueTimeFixture(Db);
                var userId = Fixture.Integer();
                f.SiteControlReader.Read<bool>(SiteControls.WIPSplitMultiDebtor).Returns(false);
                var result = await f.Subject.For(new RecordableTime(){ EntryNo = 1, StaffId = 1, CaseKey = 123, Activity = "ABCxyz"}, "en-GB", userId);
                await f.TimeSplitter.DidNotReceive().SplitTime(Arg.Any<string>(), Arg.Any<RecordableTime>(), Arg.Any<int>());
                f.TimeSplitter.DidNotReceive().AggregateSplitIntoTime(Arg.Any<RecordableTime>());
                await f.WipCosting.Received(1).For(Arg.Any<RecordableTime>(), userId);
            }

            [Fact]
            public async Task SplitsAndAggregatesForMultiDebtorCase()
            {
                var f = new ValueTimeFixture(Db);
                f.SiteControlReader.Read<bool>(SiteControls.WIPSplitMultiDebtor).Returns(true);
                f.TimeSplitter.SplitTime(Arg.Any<string>(), Arg.Any<RecordableTime>(), Arg.Any<int>()).Returns(new RecordableTime()
                {
                    EntryNo = 1, StaffId = 1, CaseKey = 123, Activity = "ABCxyz",
                    DebtorSplits = new List<DebtorSplit>
                    {
                        new DebtorSplit
                        {
                            LocalValue = 1,
                            LocalDiscount = 2,
                            DebtorNameNo = Fixture.Integer()
                        }, new DebtorSplit 
                        {
                            LocalValue = 7,
                            LocalDiscount = 3,
                            DebtorNameNo = Fixture.Integer()
                        }
                    }
                });
                f.TimeSplitter.AggregateSplitIntoTime(Arg.Any<RecordableTime>()).Returns(new TimeEntry());
                await f.Subject.For(new RecordableTime(){EntryNo = 1, StaffId = 1, CaseKey = 123, Activity = "ABCxyz"}, "zh-CN");    
                await f.TimeSplitter.Received(1).SplitTime("zh-CN", Arg.Any<RecordableTime>(), Arg.Any<int>());
                f.TimeSplitter.Received(1).AggregateSplitIntoTime(Arg.Any<RecordableTime>());
                await f.WipCosting.DidNotReceive().For(Arg.Any<RecordableTime>());
            }
        }
    }
    public class ValueTimeFixture : IFixture<ValueTime>
    {
        public ValueTimeFixture(InMemoryDbContext db)
        {
            SiteControlReader = Substitute.For<ISiteControlReader>();
            WipCosting = Substitute.For<IWipCosting>();
            WipCosting.For(Arg.Any<RecordableTime>(), Arg.Any<int>()).Returns(new WipCost());
            WipCosting.For(Arg.Any<WipCost>()).Returns(new WipCost());

            TimeSplitter = Substitute.For<ITimeSplitter>();

            var profile = new AccountingProfile();
            var m = new Mapper(new MapperConfiguration(cfg =>
            {
                cfg.AddProfile(profile);
                cfg.CreateMissingTypeMaps = true;
            }));
            Subject = new ValueTime(SiteControlReader, WipCosting, TimeSplitter, m);    
        }

        public ISiteControlReader SiteControlReader { get; set; }
        public IWipCosting WipCosting { get; set; }
        public ITimeSplitter TimeSplitter { get; set; }
        public IMapper Mapper { get; set; }
        public ValueTime Subject { get; }
    }
}
