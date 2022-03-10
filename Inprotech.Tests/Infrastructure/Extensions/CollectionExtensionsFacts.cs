using System;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Extensions
{
    public class CollectionExtensionsFacts
    {
        class Item
        {
            public string Value { get; set; }

            public string OtherValue { get; set; }

            public DateTime? NullableDateValue { get; set; }

            public DateTime DateValue { get; set; }
        }

        public class OrderByPropertyQueryableMethod
        {
            [Fact]
            public void ShouldSortInAscendingOrder()
            {
                var items = new[] {new Item {Value = "B"}, new Item {Value = "A"}};
                var result = items.AsQueryable().OrderByProperty("Value", "asc").ToArray();

                Assert.Equal(items[0], result[1]);
                Assert.Equal(items[1], result[0]);
            }

            [Fact]
            public void ShouldSortInDescendingOrder()
            {
                var items = new[] {new Item {Value = "A"}, new Item {Value = "B"}};
                var result = items.AsQueryable().OrderByProperty("Value", "desc").ToArray();

                Assert.Equal(items[0], result[1]);
                Assert.Equal(items[1], result[0]);
            }

            [Fact]
            public void ShouldUsePropertyPath()
            {
                var items = new[] {new Item {Value = "A"}, new Item {Value = "BC"}};
                var result = items.AsQueryable().OrderByProperty("Value.Length", "desc").ToArray();

                Assert.Equal(items[0], result[1]);
                Assert.Equal(items[1], result[0]);
            }
        }

        public class ThenByPropertyQueryableMethod
        {
            [Fact]
            public void ShouldSortInAscendingOrder()
            {
                var items = new[] {new Item {OtherValue = "a", Value = "B"}, new Item {OtherValue = "a", Value = "A"}};
                var result = items.AsQueryable().OrderByProperty("OtherValue", "asc").ThenByProperty("Value", "asc").ToArray();

                Assert.Equal(items[0], result[1]);
                Assert.Equal(items[1], result[0]);
            }

            [Fact]
            public void ShouldSortInDescendingOrder()
            {
                var items = new[] {new Item {OtherValue = "a", Value = "A"}, new Item {OtherValue = "a", Value = "B"}};
                var result = items.AsQueryable().OrderByProperty("OtherValue", "asc").ThenByProperty("Value", "desc").ToArray();

                Assert.Equal(items[0], result[1]);
                Assert.Equal(items[1], result[0]);
            }

            [Fact]
            public void ShouldUsePropertyPath()
            {
                var items = new[] {new Item {OtherValue = "a", Value = "A"}, new Item {OtherValue = "a", Value = "BC"}};
                var result = items.AsQueryable().OrderByProperty("OtherValue", "asc").ThenByProperty("Value.Length", "desc").ToArray();

                Assert.Equal(items[0], result[1]);
                Assert.Equal(items[1], result[0]);
            }
        }

        public class OrderByPropertyEnumerableMethod
        {
            [Fact]
            public void ShouldSortInAscendingOrder()
            {
                var items = new[] {new Item {Value = "B"}, new Item {Value = "A"}};
                var result = items.OrderByProperty("Value", "asc").ToArray();

                Assert.Equal(items[0], result[1]);
                Assert.Equal(items[1], result[0]);
            }

            [Fact]
            public void ShouldSortInDescendingOrder()
            {
                var items = new[] {new Item {Value = "A"}, new Item {Value = "B"}};
                var result = items.OrderByProperty("Value", "desc").ToArray();

                Assert.Equal(items[0], result[1]);
                Assert.Equal(items[1], result[0]);
            }
        }

        public class FilterByPropertyMethod
        {
            [Theory]
            [InlineData("gt", "2000-01-01", "2001-01-01", "2000-01-01")]
            [InlineData("gt", "2000-01-01", "2001-01-01", "2000-01-01 00:00:01")]
            [InlineData("lt", "2001-01-01", "2000-01-01", "2001-01-01")]
            [InlineData("lt", "2001-01-01", "2000-01-01", "2000-01-01 00:00:01")]
            [InlineData("eq", "2001-01-01", "2000-01-01", "2000-01-01")]
            public void ShouldFilterNullableDate(string filterOperator, string date1, string date2, string filterBy)
            {
                var items = new[]
                {
                    new Item
                    {
                        NullableDateValue = DateTime.Parse(date1)
                    },
                    new Item
                    {
                        NullableDateValue = DateTime.Parse(date2)
                    },
                    new Item
                    {
                        NullableDateValue = null
                    }
                };
                var result = items.AsQueryable().FilterByProperty("nullableDateValue", filterOperator, DateTime.Parse(filterBy));

                Assert.Equal(items[1], result.Single());
            }

            [Theory]
            [InlineData("gt", "2000-01-01", "2001-01-01", "2000-01-01")]
            [InlineData("gt", "2000-01-01", "2001-01-01", "2000-01-01 00:00:01")]
            [InlineData("lt", "2001-01-01", "2000-01-01", "2001-01-01")]
            [InlineData("lt", "2001-01-01", "2000-01-01", "2000-01-01 00:00:01")]
            [InlineData("eq", "2001-01-01", "2000-01-01", "2000-01-01")]
            public void ShouldFilterDate(string filterOperator, string date1, string date2, string filterBy)
            {
                var items = new[]
                {
                    new Item
                    {
                        DateValue = DateTime.Parse(date1)
                    },
                    new Item
                    {
                        DateValue = DateTime.Parse(date2)
                    }
                };
                var result = items.AsQueryable().FilterByProperty("dateValue", filterOperator, DateTime.Parse(filterBy));

                Assert.Equal(items[1], result.Single());
            }

            [Fact]
            public void ShouldCompareDateComponentForEquality()
            {
                var theDay = Fixture.Today();

                var justBeforeTheDayStarts = theDay.AddMilliseconds(-1);

                var theDayJustStarted = theDay.AddMilliseconds(1);

                var justBeforeTheDayEnds = theDay.AddDays(1).AddMilliseconds(-1);

                var items = new[]
                {
                    new Item
                    {
                        DateValue = justBeforeTheDayStarts
                    },
                    new Item
                    {
                        DateValue = theDayJustStarted
                    },
                    new Item
                    {
                        DateValue = justBeforeTheDayEnds
                    }
                };
                var result = items.AsQueryable().FilterByProperty("dateValue", "eq", theDay).ToArray();

                Assert.Equal(2, result.Count());
                Assert.Contains(items[1], result);
                Assert.Contains(items[2], result);
            }

            [Fact]
            public void ShouldFilterByInOperator()
            {
                var items = new[] {new Item {Value = "A"}, new Item {Value = "B"}};
                var result = items.AsQueryable().FilterByProperty("value", "in", "A,C");

                Assert.Equal(items[0], result.Single());
            }

            [Fact]
            public void ShouldFilterByNotInOperator()
            {
                var items = new[] {new Item {Value = "A"}, new Item {Value = "B"}};
                var result = items.AsQueryable().FilterByProperty("value", "notIn", "A,C");

                Assert.Equal(items[1], result.Single());
            }

            [Fact]
            public void ShouldFilterByNull()
            {
                var items = new[] {new Item {Value = null}, new Item {Value = "BCD"}};
                var result = items.AsQueryable().FilterByProperty("value", "in", "null");

                Assert.Equal(items[0], result.Single());
            }

            [Fact]
            public void ShouldFilterContains()
            {
                var items = new[]
                {
                    new Item
                    {
                        Value = "abcde"
                    },
                    new Item
                    {
                        Value = "efghi"
                    }
                };

                var result = items.AsQueryable().FilterByProperty("value", "contains", "bc");

                Assert.Equal(items[0], result.Single());
            }

            [Fact]
            public void ShouldFilterEquals()
            {
                var items = new[]
                {
                    new Item
                    {
                        Value = "abcde"
                    },
                    new Item
                    {
                        Value = "efghi"
                    }
                };

                var result = items.AsQueryable().FilterByProperty("value", "eq", "abcde");

                Assert.Equal(items[0], result.Single());
            }

            [Fact]
            public void ShouldFilterStartsWith()
            {
                var items = new[]
                {
                    new Item
                    {
                        Value = "abcde"
                    },
                    new Item
                    {
                        Value = "efghi"
                    }
                };

                var result = items.AsQueryable().FilterByProperty("value", "startswith", "e");

                Assert.Equal(items[1], result.Single());
            }

            [Fact]
            public void ShouldUsePropertyPath()
            {
                var items = new[] {new Item {Value = "A"}, new Item {Value = "BCD"}};
                var result = items.AsQueryable().FilterByProperty("value.length", "in", "1,2");

                Assert.Equal(items[0], result.Single());
            }
        }

        public class ThenByPropertyMethod
        {
            [Fact]
            public void ShouldSortInAscendingOrder()
            {
                var items = new[]
                {
                    new Item {Value = "A", OtherValue = "B"},
                    new Item {Value = "A", OtherValue = "A"},
                    new Item {Value = "A", OtherValue = "C"},
                    new Item {Value = "B", OtherValue = "A"}
                };

                var result = items.OrderBy(_ => _.Value).ThenByProperty("OtherValue", "asc").ToArray();

                Assert.Equal("A", result[0].OtherValue);
                Assert.Equal("B", result[1].OtherValue);
                Assert.Equal("C", result[2].OtherValue);
                Assert.Equal("A", result[3].OtherValue);
                Assert.Equal("B", result[3].Value);
            }

            [Fact]
            public void ShouldSortInDescendingOrder()
            {
                var items = new[]
                {
                    new Item {Value = "A", OtherValue = "B"},
                    new Item {Value = "A", OtherValue = "A"},
                    new Item {Value = "A", OtherValue = "C"},
                    new Item {Value = "B", OtherValue = "A"}
                };

                var result = items.OrderBy(_ => _.Value).ThenByProperty("OtherValue", "desc").ToArray();

                Assert.Equal("C", result[0].OtherValue);
                Assert.Equal("B", result[1].OtherValue);
                Assert.Equal("A", result[2].OtherValue);
                Assert.Equal("A", result[3].OtherValue);
                Assert.Equal("B", result[3].Value);
            }
        }

        public class ThenByNullsLastMethod
        {
            [Fact]
            public void ShouldSortNullsLast()
            {
                var items = new[]
                {
                    new Item {Value = "A", OtherValue = "B"},
                    new Item {Value = "A", OtherValue = "A"},
                    new Item {Value = "A", OtherValue = null},
                    new Item {Value = "B", OtherValue = "A"}
                };

                var result = items.OrderBy(_ => _.Value).ThenByNullsLast("OtherValue").ToArray();

                Assert.Equal("A", result[0].OtherValue);
                Assert.Equal("B", result[1].OtherValue);
                Assert.Null(result[2].OtherValue);
                Assert.Equal("B", result[3].Value);
            }
        }

        public class ThenByNullsLastDescendingMethod
        {
            [Fact]
            public void ShouldSortNullsLastDescending()
            {
                var items = new[]
                {
                    new Item {Value = "A", OtherValue = "B"},
                    new Item {Value = "A", OtherValue = "A"},
                    new Item {Value = "A", OtherValue = null},
                    new Item {Value = "B", OtherValue = "A"}
                };

                var result = items.OrderBy(_ => _.Value).ThenByNullsLastDescending("OtherValue").ToArray();

                Assert.Equal("B", result[0].OtherValue);
                Assert.Equal("A", result[1].OtherValue);
                Assert.Null(result[2].OtherValue);
                Assert.Equal("B", result[3].Value);
            }
        }
    }
}