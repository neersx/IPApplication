using System.Linq;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class DatesAlignerFacts
    {
        readonly DatesAligner _subject = new DatesAligner();

        [Fact]
        public void AlignsByDateThenAllocateCycles()
        {
            var lhs = new[]
            {
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-01-01"),
                    Ref = new PtoDateInfo
                    {
                        Ref = "a",
                        Description = "some extended info"
                    }
                },
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-02-02"),
                    Ref = new PtoDateInfo
                    {
                        Ref = "b",
                        Description = string.Empty
                    }
                },
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-03-03"),
                    Ref = new PtoDateInfo {Ref = "c"}
                }
            };

            var rhs = new[]
            {
                new Date<short>
                {
                    DateTime = Fixture.Date("2002-02-02"),
                    Ref = 1
                }
            };

            var r = _subject.Align(lhs, rhs).ToArray();

            var r1 = r.ElementAt(0);
            var r2 = r.ElementAt(1);
            var r3 = r.ElementAt(2);

            Assert.Equal(3, r.Count());

            Assert.Equal(Fixture.Date("2002-01-01"), r1.DateTimeLhs);
            Assert.Null(r1.DateTimeRhs);
            Assert.Equal("a", r1.RefLhs.Ref);
            Assert.Equal("some extended info", r1.RefLhs.Description);
            Assert.Null(r1.RefRhs);

            Assert.Equal(Fixture.Date("2002-02-02"), r2.DateTimeLhs);
            Assert.Equal(Fixture.Date("2002-02-02"), r2.DateTimeRhs);
            Assert.Equal("b", r2.RefLhs.Ref);
            Assert.Equal(string.Empty, r2.RefLhs.Description);
            Assert.Equal((short) 1, r2.RefRhs);

            Assert.Equal(Fixture.Date("2002-03-03"), r3.DateTimeLhs);
            Assert.Null(r3.DateTimeRhs);
            Assert.Equal("c", r3.RefLhs.Ref);
            Assert.Null(r3.RefLhs.Description);
            Assert.Equal((short) 2, r3.RefRhs);
        }

        [Fact]
        public void AllocateCyclesFromAlignedDatesLhs()
        {
            var lhs = new[]
            {
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-01-01"),
                    Ref = new PtoDateInfo {Ref = "a"}
                },
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-02-02"),
                    Ref = new PtoDateInfo
                    {
                        Ref = "b",
                        Description = "some extended info"
                    }
                },
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-03-03"),
                    Ref = new PtoDateInfo {Ref = "c"}
                }
            };

            var rhs = new[]
            {
                new Date<short>
                {
                    DateTime = Fixture.Date("2002-01-01"),
                    Ref = 1
                },
                new Date<short>
                {
                    DateTime = Fixture.Date("2002-04-04"),
                    Ref = 2
                }
            };

            var r = _subject.Align(lhs, rhs).ToArray();

            var r1 = r.ElementAt(0);
            var r2 = r.ElementAt(1);
            var r3 = r.ElementAt(2);

            Assert.Equal(3, r.Count());

            Assert.Equal(Fixture.Date("2002-01-01"), r1.DateTimeLhs);
            Assert.Equal(Fixture.Date("2002-01-01"), r1.DateTimeRhs);
            Assert.Equal("a", r1.RefLhs.Ref);
            Assert.Null(r1.RefLhs.Description);
            Assert.Equal((short) 1, r1.RefRhs);

            Assert.Equal(Fixture.Date("2002-02-02"), r2.DateTimeLhs);
            Assert.Equal(Fixture.Date("2002-04-04"), r2.DateTimeRhs);
            Assert.Equal("b", r2.RefLhs.Ref);
            Assert.Equal("some extended info", r2.RefLhs.Description);
            Assert.Equal((short) 2, r2.RefRhs);

            Assert.Equal(Fixture.Date("2002-03-03"), r3.DateTimeLhs);
            Assert.Null(r3.DateTimeRhs);
            Assert.Equal("c", r3.RefLhs.Ref);
            Assert.Null(r3.RefLhs.Description);
            Assert.Equal((short) 3, r3.RefRhs);
        }

        [Fact]
        public void AllocatesAscendingCyclesToUnmatchedItems()
        {
            var lhs = new[]
            {
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Today(),
                    Ref = new PtoDateInfo
                    {
                        Ref = "a",
                        Description = "some extended info"
                    }
                },
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.PastDate(),
                    Ref = new PtoDateInfo
                    {
                        Ref = "b",
                        Description = "more extended info"
                    }
                }
            };

            var r = _subject.Align(lhs, Enumerable.Empty<Date<short>>()).ToArray();

            Assert.Equal(2, r.Count());

            Assert.Equal(Fixture.Today(), r.First().DateTimeLhs);
            Assert.Equal("a", r.First().RefLhs.Ref);
            Assert.Equal("some extended info", r.First().RefLhs.Description);
            Assert.Equal((short) 1, r.First().RefRhs);

            Assert.Equal(Fixture.PastDate(), r.Last().DateTimeLhs);
            Assert.Equal("b", r.Last().RefLhs.Ref);
            Assert.Equal("more extended info", r.Last().RefLhs.Description);
            Assert.Equal((short) 2, r.Last().RefRhs);
        }

        [Fact]
        public void DeriveCyclesFromRhsFromAlignedDates()
        {
            var lhs = new[]
            {
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-01-01"),
                    Ref = new PtoDateInfo {Ref = "a"}
                }
            };

            var rhs = new[]
            {
                new Date<short>
                {
                    DateTime = Fixture.Date("2002-01-01"),
                    Ref = 1
                },
                new Date<short>
                {
                    DateTime = Fixture.Date("2002-04-04"),
                    Ref = 2
                }
            };

            var r = _subject.Align(lhs, rhs).ToArray();

            var r1 = r.ElementAt(0);
            var r2 = r.ElementAt(1);

            Assert.Equal(2, r.Count());

            Assert.Equal(Fixture.Date("2002-01-01"), r1.DateTimeLhs);
            Assert.Equal(Fixture.Date("2002-01-01"), r1.DateTimeRhs);
            Assert.Equal("a", r1.RefLhs.Ref);
            Assert.Equal((short) 1, r1.RefRhs);

            Assert.Null(r2.DateTimeLhs);
            Assert.Null(r2.RefLhs);
            Assert.Equal(Fixture.Date("2002-04-04"), r2.DateTimeRhs);
            Assert.Equal((short) 2, r2.RefRhs);
        }

        [Fact]
        public void DoesNotAlignInOppositeDirection()
        {
            var lhs = new[]
            {
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-02-02"), /* matches cycle 2 */
                    Ref = new PtoDateInfo
                    {
                        Ref = "a",
                        Description = "some extended info"
                    }
                },
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-03-03"), /* will not match as it is in opposite direction */
                    Ref = new PtoDateInfo
                    {
                        Ref = "b",
                        Description = "more extended info"
                    }
                }
            };

            var rhs = new[]
            {
                new Date<short>
                {
                    DateTime = Fixture.Date("2002-03-03"),
                    Ref = 1
                },
                new Date<short>
                {
                    DateTime = Fixture.Date("2002-02-02"),
                    Ref = 2
                }
            };

            var r = _subject.Align(lhs, rhs).ToArray();

            var r1 = r.ElementAt(0);
            var r2 = r.ElementAt(1);
            var r3 = r.ElementAt(2);

            Assert.Equal(3, r.Count());

            Assert.Null(r1.DateTimeLhs);
            Assert.Equal(Fixture.Date("2002-03-03"), r1.DateTimeRhs);
            Assert.Null(r1.RefLhs);
            Assert.Equal((short) 1, r1.RefRhs);

            Assert.Equal(Fixture.Date("2002-02-02"), r2.DateTimeLhs);
            Assert.Equal(Fixture.Date("2002-02-02"), r2.DateTimeRhs);
            Assert.Equal("a", r2.RefLhs.Ref);
            Assert.Equal("some extended info", r2.RefLhs.Description);
            Assert.Equal((short) 2, r2.RefRhs);

            Assert.Equal(Fixture.Date("2002-03-03"), r3.DateTimeLhs);
            Assert.Null(r3.DateTimeRhs);
            Assert.Equal("b", r3.RefLhs.Ref);
            Assert.Equal("more extended info", r3.RefLhs.Description);
            Assert.Equal((short) 3, r3.RefRhs);
        }

        [Fact]
        public void MixesBothSidesThenAllocateCycles()
        {
            var lhs = new[]
            {
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-01-01"),
                    Ref = new PtoDateInfo
                    {
                        Ref = "a",
                        Description = "some extended info"
                    }
                },
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-02-02"),
                    Ref = new PtoDateInfo
                    {
                        Ref = "b",
                        Description = "more extended info"
                    }
                }
            };

            var rhs = new[]
            {
                new Date<short>
                {
                    DateTime = Fixture.Date("2003-01-01"),
                    Ref = 1
                }
            };

            var r = _subject.Align(lhs, rhs).ToArray();

            Assert.Equal(2, r.Count());

            Assert.Equal(Fixture.Date("2002-01-01"), r.First().DateTimeLhs);
            Assert.Equal(Fixture.Date("2003-01-01"), r.First().DateTimeRhs);
            Assert.Equal("a", r.First().RefLhs.Ref);
            Assert.Equal("some extended info", r.First().RefLhs.Description);
            Assert.Equal((short) 1, r.First().RefRhs);

            Assert.Equal(Fixture.Date("2002-02-02"), r.Last().DateTimeLhs);
            Assert.Null(r.Last().DateTimeRhs);
            Assert.Equal("b", r.Last().RefLhs.Ref);
            Assert.Equal("more extended info", r.Last().RefLhs.Description);
            Assert.Equal((short) 2, r.Last().RefRhs);
        }

        [Fact]
        public void ReturnGapsBetweenAlignedDates()
        {
            var lhs = new[]
            {
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-01-01"),
                    Ref = new PtoDateInfo
                    {
                        Ref = "a",
                        Description = "some extended info"
                    }
                },
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-02-02"),
                    Ref = new PtoDateInfo {Ref = "b"}
                },
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-03-03"),
                    Ref = new PtoDateInfo {Ref = "c"}
                },
                new Date<PtoDateInfo>
                {
                    DateTime = Fixture.Date("2002-04-04"),
                    Ref = new PtoDateInfo
                    {
                        Ref = "d",
                        Description = "more extended info"
                    }
                }
            };

            var rhs = new[]
            {
                new Date<short>
                {
                    DateTime = Fixture.Date("2002-02-02"),
                    Ref = 1
                },
                new Date<short>
                {
                    DateTime = Fixture.Date("2002-04-04"),
                    Ref = 2
                }
            };

            var r = _subject.Align(lhs, rhs).ToArray();

            var r1 = r.ElementAt(0);
            var r2 = r.ElementAt(1);
            var r3 = r.ElementAt(2);
            var r4 = r.ElementAt(3);

            Assert.Equal(4, r.Count());

            Assert.Equal(Fixture.Date("2002-01-01"), r1.DateTimeLhs);
            Assert.Null(r1.DateTimeRhs);
            Assert.Equal("a", r1.RefLhs.Ref);
            Assert.Equal("some extended info", r1.RefLhs.Description);
            Assert.Null(r1.RefRhs);

            Assert.Equal(Fixture.Date("2002-02-02"), r2.DateTimeLhs);
            Assert.Equal(Fixture.Date("2002-02-02"), r2.DateTimeRhs);
            Assert.Equal("b", r2.RefLhs.Ref);
            Assert.Null(r2.RefLhs.Description);
            Assert.Equal((short) 1, r2.RefRhs);

            Assert.Equal(Fixture.Date("2002-03-03"), r3.DateTimeLhs);
            Assert.Null(r3.DateTimeRhs);
            Assert.Equal("c", r3.RefLhs.Ref);
            Assert.Null(r3.RefLhs.Description);
            Assert.Null(r3.RefRhs);

            Assert.Equal(Fixture.Date("2002-04-04"), r4.DateTimeLhs);
            Assert.Equal(Fixture.Date("2002-04-04"), r4.DateTimeRhs);
            Assert.Equal("d", r4.RefLhs.Ref);
            Assert.Equal("more extended info", r4.RefLhs.Description);
            Assert.Equal((short) 2, r4.RefRhs);
        }
    }
}