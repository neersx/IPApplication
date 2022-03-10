using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.EndToEnd.Components;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Search
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class CaseSearchTest : IntegrationTest
    {
        [Test]
        public void QuickSearchReturnsColumnsAndRows()
        {
            var setup = new QuickSearchDbSetup().Setup();

            var db = new SqlDbContext();
            var columns = (from qc in db.Set<QueryContent>()
                           join qcol in db.Set<QueryColumn>() on qc.ColumnId equals qcol.ColumnId
                           where qc.PresentationId == -2
                           orderby qc.DisplaySequence
                           select qcol).ToList();                

            var result = ApiClient.Post<SearchResult>("search/case", JsonConvert.SerializeObject(CreateCaseSearchRequest(setup.SearchBy)));

            Assert.AreEqual(columns.Count, result.Columns.Count());

            Foreach.Enum2(columns,
                               result.Columns,
                               (a, b) =>
                                   {
                                       Assert.IsTrue(string.Equals(a.ColumnLabel, b.Title, StringComparison.InvariantCultureIgnoreCase), "columns should be shown in order that is configured in DB");
                                   });

            Assert.AreEqual(setup.Irns.Count, result.Rows.Count(), "all IRNs should be found");
        }

        [Test]
        public void QuickSearchReturnsColumnsAndRowsWithFilter()
        {
            var setup = new QuickSearchDbSetup().Setup();
            
            var result = ApiClient.Post<SearchResult>("search/case", JsonConvert.SerializeObject(CreateCaseSearchRequest(setup.SearchBy, "in", "AU,US")));
            Assert.True((setup.Irns.Count - 1) == result.Rows.Count(), "Rows are filterred");

            result = ApiClient.Post<SearchResult>("search/case", JsonConvert.SerializeObject(CreateCaseSearchRequest(setup.SearchBy, "notIn", "AD")));
            Assert.IsTrue(setup.Irns.Count-1 == result.Rows.Count(), "Rows are filterred");
        }

        [Test]
        public void QuickSearchReturnsFilterOptions()
        {
            var setup = new QuickSearchDbSetup().Setup();

            var result = ApiClient.Post<IEnumerable<CodeDescription>>("search/case/filterData", JsonConvert.SerializeObject(CreateColumnFilterParams(setup.SearchBy, "countryname__7_")));
            Assert.True(result.Count() == 2, "Correct number of filter options are returned");
        }

        SearchRequestParams<CaseSearchRequestFilter> CreateCaseSearchRequest(string searchBy, string filterOperator = "", string filterValue = "")
        {
            var caseSearchRequest = new List<CaseSearchRequest>
            {
                new CaseSearchRequest
                {
                    AnySearch = new SearchElement
                    {
                        Operator = 2,
                        Value = searchBy
                    }
                }
            };
            var caseSearchRequestParams = new SearchRequestParams<CaseSearchRequestFilter>
            {
                Criteria = new CaseSearchRequestFilter()
                {
                    SearchRequest = caseSearchRequest
                },
                IsHosted = false,
                QueryContext = QueryContext.CaseSearch
            };

            if (string.IsNullOrEmpty(filterOperator) && string.IsNullOrEmpty(filterValue))
                return caseSearchRequestParams;

            caseSearchRequestParams.Params = new CommonQueryParameters
            {
                Filters = new List<CommonQueryParameters.FilterValue>
                {
                    new CommonQueryParameters.FilterValue
                    {
                        Field = "countryname__7_",
                        Operator = filterOperator,
                        Value = filterValue
                    }
                }
            };

            return caseSearchRequestParams;
        }

        ColumnFilterParams<CaseSearchRequestFilter> CreateColumnFilterParams(string searchBy, string column)
        {
            var caseSearchRequestParams = CreateCaseSearchRequest(searchBy);

            return new ColumnFilterParams<CaseSearchRequestFilter>
            {
                Column = column,
                Criteria = caseSearchRequestParams.Criteria,
                Params = new CommonQueryParameters(),
                IsHosted = false,
                QueryContext = QueryContext.CaseSearch
            };
        }
    }

    static class Foreach
    {
        public static void Enum2<TFirst, TSecond>(IEnumerable<TFirst> s1, IEnumerable<TSecond> s2, Action<TFirst, TSecond> func)
        {
            using (var e1 = s1.GetEnumerator())
                using (var e2 = s2.GetEnumerator())
                {
                    while (e1.MoveNext() && e2.MoveNext())
                    {
                        func(e1.Current, e2.Current);
                    }
                }
        }
    }
}
