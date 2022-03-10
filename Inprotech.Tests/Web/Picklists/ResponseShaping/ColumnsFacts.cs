using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Reflection;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Web.Picklists.ResponseShaping;
using Xunit;

namespace Inprotech.Tests.Web.Picklists.ResponseShaping
{
    public class ColumnsFacts
    {
        public class EnrichMethod
        {
            public EnrichMethod()
            {
                _api = new PayloadFixtureApiFixture();
                _fixture = new ColumnsFixture();
                _enriched = new Dictionary<string, object>();
            }

            readonly ColumnsFixture _fixture;
            readonly PayloadFixtureApiFixture _api;
            readonly Dictionary<string, dynamic> _enriched;
            readonly IEnumerable<object> _emptyPayload = new object[0];

            [Fact]
            public void OrdersResultByDisplayOrderAttribute()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithPayloadWithDisplayOrder)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                var columns = ((IEnumerable<Column>) _enriched["Columns"]).ToArray();

                Assert.Equal(
                             new[] {"displayTheFirst", "displayTheSecond", "displayTheThird", "displayTheNullth"},
                             columns.Select(c => c.Field));
            }

            [Fact]
            public void ShouldEnrich()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithPayloadWithEverything)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.True(_enriched.ContainsKey("Columns"));
            }

            [Fact]
            public void ShouldNotReturnTitle()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithPayloadWithEverything)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                var column = ((IEnumerable<Column>) _enriched["Columns"]).Single(_ => _.Field == "noDisplayAttribute");

                Assert.Null(column.Title);
            }

            [Fact]
            public void ShouldReturnColumnsTitleResource()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithDisplayColumn)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                var column = ((IEnumerable<Column>) _enriched["Columns"]).Single();

                Assert.Equal("picklist.payloadwithdisplaycolumn.custom hello", column.Title);
            }

            [Fact]
            public void ShouldReturnDefinedPicklistDescriptionField()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithPayloadWithDescription)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                var column = ((IEnumerable<Column>) _enriched["Columns"]).Single();

                Assert.Equal("picklist.payloadwithdescription.Description", column.Title);
                Assert.True(column.Description.GetValueOrDefault());
                Assert.False(column.Hidden.GetValueOrDefault());
            }

            [Fact]
            public void ShouldReturnDefinedPicklistDescriptionFieldWithCustomDescription()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithPayloadWithCustomDescription)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                var column = ((IEnumerable<Column>) _enriched["Columns"]).Single();

                Assert.Equal("picklist.payloadwithcustomdescription.custom description", column.Title);
                Assert.True(column.Description.GetValueOrDefault());
                Assert.False(column.Hidden.GetValueOrDefault());
            }

            [Fact]
            public void ShouldReturnDefinedPicklistKey()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithPayloadWithKey)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                var column = ((IEnumerable<Column>) _enriched["Columns"]).Single();

                Assert.True(column.Key.GetValueOrDefault());
            }

            [Fact]
            public void ShouldReturnFieldNameStartsWithLowerCase()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithPayloadWithEverything)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                var columns = (IEnumerable<Column>) _enriched["Columns"];

                Assert.Equal(
                             new[] {"hasDisplayOrderAttribute", "key", "description", "hasDisplayAttribute1", "noDisplayAttribute", "hasDisplayAttribute2"},
                             columns.Select(_ => _.Field));
            }

            [Fact]
            public void ShuoldReturnFilterableColumns()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithPayloadWithFilterable)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                var column = ((IEnumerable<Column>) _enriched["Columns"]).Single();

                Assert.True(column.Filterable);
                Assert.Equal("api/picklists/filter", column.FilterApi);
            }
        }

        public class ColumnsFixture : IFixture<Columns>
        {
            public ColumnsFixture()
            {
                Subject = new Columns();
            }

            public HttpActionExecutedContext ActionContext { get; private set; }

            public Columns Subject { get; }

            public ColumnsFixture WithActionContextFor(object payload, Action action)
            {
                ActionContext = TestHelper.CreateActionExecutedContext(payload, Of(action));
                return this;
            }

            public MethodInfo Of(Action a)
            {
                return a.Method;
            }
        }

        public class PayloadFixtureApiFixture
        {
            [PicklistPayload(typeof(PayloadWithDisplayColumn))]
            public void WithDisplayColumn()
            {
            }

            [PicklistPayload(typeof(PayloadWithCustomDescription))]
            public void WithPayloadWithCustomDescription()
            {
            }

            [PicklistPayload(typeof(PayloadWithKey))]
            public void WithPayloadWithKey()
            {
            }

            [PicklistPayload(typeof(PayloadWithDisplayOrder))]
            public void WithPayloadWithDisplayOrder()
            {
            }

            [PicklistPayload(typeof(PayloadWithEverything))]
            public void WithPayloadWithEverything()
            {
            }

            [PicklistPayload(typeof(PayloadWithDescription))]
            public void WithPayloadWithDescription()
            {
            }

            [PicklistPayload(typeof(PayloadWithFilterable))]
            public void WithPayloadWithFilterable()
            {
            }
        }

        public class PayloadWithDisplayColumn
        {
            [DisplayName(@"custom hello")]
            public string Hello { get; set; }
        }

        public class PayloadWithCustomDescription
        {
            [PicklistDescription(@"custom description")]
            public string Hello { get; set; }
        }

        public class PayloadWithDescription
        {
            [PicklistDescription]
            public string Hello { get; set; }
        }

        public class PayloadWithKey
        {
            [PicklistKey]
            public string Hello { get; set; }
        }

        public class PayloadWithFilterable
        {
            [PicklistColumn(filterable: true, filterApi: "api/picklists/filter")]
            public string Filterable { get; set; }
        }

        public class PayloadWithDisplayOrder
        {
            [DisplayOrder(2)]
            public string DisplayTheThird { get; set; }

            [DisplayOrder(0)]
            public string DisplayTheFirst { get; set; }

            public string DisplayTheNullth { get; set; }

            [DisplayOrder(1)]
            public string DisplayTheSecond { get; set; }
        }

        public class PayloadWithEverything
        {
            [PicklistKey]
            public string Key { get; set; }

            [PicklistDescription]
            public string Description { get; set; }

            [DisplayName(@"HasDisplayAttribute1")]
            public string HasDisplayAttribute1 { get; set; }

            public string NoDisplayAttribute { get; set; }

            [DisplayName(@"HasDisplayAttribute2")]
            public string HasDisplayAttribute2 { get; set; }

            [DisplayOrder(1)]
            public string HasDisplayOrderAttribute { get; set; }
        }
    }
}