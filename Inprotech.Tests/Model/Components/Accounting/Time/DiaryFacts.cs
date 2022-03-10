using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Accounting;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Time
{
    public class DiaryFactsGetWholeChainFor
    {
        readonly Diary[] _input =
        {
            new Diary {EntryNo = 1},
            new Diary {EntryNo = 2, ParentEntryNo = 1},
            new Diary {EntryNo = 3, ParentEntryNo = 2},
            new Diary {EntryNo = 4, ParentEntryNo = 3},
            new Diary {EntryNo = 55},
            new Diary {EntryNo = 66},
            new Diary {EntryNo = 67, ParentEntryNo = 66}
        };

        [Fact]
        public void ReturnsEmptyIfNoEntriesFoundInChain()
        {
            var result = _input.GetWholeChainFor(99);
            Assert.Empty(result);
        }

        [Fact]
        public void ReturnsChildEntryOnlyIfNoOtherEntriesFound()
        {
            var result = _input.GetWholeChainFor(55).ToArray();
            Assert.Equal(1, result.Length);
            Assert.Equal(55, result[0].EntryNo);
        }

        [Fact]
        public void IncludesDownwardAndUpwardChain()
        {
            var result = _input.GetWholeChainFor(3).ToArray();
            Assert.Equal(4, result.Length);
            Assert.Equal(4, result[0].EntryNo);
            Assert.Equal(3, result[1].EntryNo);
            Assert.Equal(2, result[2].EntryNo);
            Assert.Equal(1, result[3].EntryNo);
        }

        [Fact]
        public void WorksCorrectlyForTopEntry()
        {
            var result = _input.GetWholeChainFor(1).ToArray();
            Assert.Equal(4, result.Length);
            Assert.Equal(4, result[0].EntryNo);
            Assert.Equal(3, result[1].EntryNo);
            Assert.Equal(2, result[2].EntryNo);
            Assert.Equal(1, result[3].EntryNo);
        }

        [Fact]
        public void WorksCorrectlyForLastEntry()
        {
            var result = _input.GetWholeChainFor(4).ToArray();
            Assert.Equal(4, result.Length);
            Assert.Equal(4, result[0].EntryNo);
            Assert.Equal(3, result[1].EntryNo);
            Assert.Equal(2, result[2].EntryNo);
            Assert.Equal(1, result[3].EntryNo);
        }
    }

    public class DiaryFactsForGetDownwardChainMethod
    {
        readonly Diary[] _input =
        {
            new Diary {EntryNo = 1},
            new Diary {EntryNo = 2, ParentEntryNo = 1},
            new Diary {EntryNo = 3, ParentEntryNo = 2},
            new Diary {EntryNo = 4, ParentEntryNo = 3},
            new Diary {EntryNo = 55},
            new Diary {EntryNo = 66},
            new Diary {EntryNo = 67, ParentEntryNo = 66}
        };

        [Fact]
        public void GetChainForRetunsEmptyIfNoEntriesFoundInChain()
        {
            var result = _input.GetDownwardChainFor(99);
            Assert.Empty(result);
        }

        [Fact]
        public void GetChainForIncludesChildEntry()
        {
            const int inputEntryNo = 67;

            var result = _input.GetDownwardChainFor(inputEntryNo);
            Assert.NotNull(result.SingleOrDefault(_ => _.EntryNo == inputEntryNo));
        }

        [Fact]
        public void GetChainForIncludesMultipleParentLevels()
        {
            const int inputEntryNo = 4;
            var result = _input.GetDownwardChainFor(inputEntryNo).ToArray();

            var parentCount = result.Count(_ => _.EntryNo != inputEntryNo);
            Assert.Equal(3, parentCount);
        }
    }

    public class DiaryFactsForIQuerableMethod
    {
        static IQueryable<Diary> Input => GenerateDiaryEntries();
        const int ExpectedCount = 8;

        static IQueryable<Diary> GenerateDiaryEntries()
        {
            return new List<Diary>
            {
                NewDiary(),
                NewDiary(transno: 1),
                NewDiary(isTimer: 1),
                NewDiary(activity: null),
                NewDiary(caseId: null),
                NewDiary(chargeoutRate: null),
                NewDiary(baseTotalTime: null),
                NewDiary(baseTotalTime: true),
                NewDiary(nameNo: null)
            }.AsQueryable();

            Diary NewDiary(int isTimer = 0, int? transno = null, string activity = "Something", int? caseId = 10, decimal? chargeoutRate = 100, bool? baseTotalTime = false, int? nameNo = 10)
            {
                DateTime? totalTime;
                if (baseTotalTime == null)
                {
                    totalTime = null;
                }
                else
                {
                    totalTime = baseTotalTime == true ? new DateTime(1899, 1, 1) : new DateTime(1899, 1, 1).AddDays(10);
                }

                return new Diary
                {
                    TransactionId = transno,
                    TotalTime = totalTime,
                    IsTimer = isTimer,
                    Activity = activity,
                    CaseId = caseId,
                    ChargeOutRate = chargeoutRate,
                    NameNo = nameNo
                };
            }
        }

        [Fact]
        public void CheckExcludePosted()
        {
            var result = Input.ExcludePosted();
            Assert.Equal(ExpectedCount, result.Count());
        }

        [Fact]
        public void ExcludeExcludeContinuedParentEntries()
        {
            var result = Input.ExcludeContinuedParentEntries();
            Assert.Equal(ExpectedCount, result.Count());
        }

        [Fact]
        public void ExcludeEntriesWithNoDuration()
        {
            var result = Input.ExcludeEntriesWithNoDuration();
            Assert.Equal(ExpectedCount - 1, result.Count());
        }

        [Fact]
        public void CheckExcludeRunningTimerEntries()
        {
            var result = Input.ExcludeRunningTimerEntries();
            Assert.Equal(ExpectedCount, result.Count());
        }

        [Fact]
        public void CheckExcludeEntriesWithoutActivity()
        {
            var result = Input.ExcludeEntriesWithoutActivity();
            Assert.Equal(ExpectedCount, result.Count());
        }

        [Fact]
        public void CheckExcludeEntriesWithoutCase()
        {
            var result = Input.ExcludeEntriesWithoutCase(true);
            Assert.Equal(ExpectedCount, result.Count());

            result = Input.ExcludeEntriesWithoutCase(false);
            Assert.Equal(ExpectedCount + 1, result.Count());
        }

        [Fact]
        public void CheckExcludeEntriesWithoutRate()
        {
            var result = Input.ExcludeEntriesWithoutRate(true);
            Assert.Equal(ExpectedCount, result.Count());

            result = Input.ExcludeEntriesWithoutRate(false);
            Assert.Equal(ExpectedCount + 1, result.Count());
        }
    }

    public class DiaryFactsForClearParentValues
    {
        [Fact]
        public void ClearValuesForProvidedEntry()
        {
            var diary = new Diary
            {
                StartTime = Fixture.Today(),
                FinishTime = Fixture.Today().AddHours(2),
                TotalTime = new DateTime(1899, 1, 1).AddHours(2),
                TimeCarriedForward = new DateTime(1899, 1, 1).AddHours(2),
                TotalUnits = 100,
                TimeValue = 100,
                ChargeOutRate = 10,
                DiscountValue = 10,
                ForeignDiscount = 10,
                CostCalculation1 = 10,
                CostCalculation2 = 10,
                EntryNo = 10,
                ParentEntryNo = 11
            };

            diary.ClearParentValues();
            Assert.Equal(10, diary.EntryNo);
            Assert.Equal(11, diary.ParentEntryNo);
            Assert.Equal(Fixture.Today(), diary.StartTime);
            Assert.Equal(Fixture.Today().AddHours(2), diary.FinishTime);
            Assert.Null(diary.TotalTime);
            Assert.Null(diary.TimeCarriedForward);
            Assert.Null(diary.TotalUnits);
            Assert.Null(diary.TimeValue);
            Assert.Null(diary.DiscountValue);
            Assert.Null(diary.ForeignDiscount);
            Assert.Null(diary.CostCalculation1);
            Assert.Null(diary.CostCalculation2);
        }
    }
}