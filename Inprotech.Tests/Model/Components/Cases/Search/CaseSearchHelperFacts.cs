using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Queries;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Search
{
    public class CaseSearchHelperFacts
    {
        public class ConstructXmlFilterMethod
        {
            [Fact]
            public void AddColumnFiltersIntoSecondXmlFilter()
            {
                var filterCriteria = "<Search><Report><ReportTitle>UK Trademark</ReportTitle></Report><Filtering><csw_ListCase><FilterCriteriaGroup><FilterCriteria ID=\'1\'><AccessMode>1</AccessMode><IsAdvancedFilter>false</IsAdvancedFilter><StandingInstructions IncludeInherited=\'0\' /><StatusFlags CheckDeadCaseRestriction=\'1\' /><CountryCodes Operator=\'0\'>GB</CountryCodes><InheritedName /><CaseNameGroup /><AttributeGroup BooleanOr=\'0\' /><Event Operator=\'\' IsRenewalsOnly=\'0\' IsNonRenewalsOnly=\'0\' ByEventDate=\'1\'><Period><Type></Type><Quantity></Quantity></Period></Event><Actions /></FilterCriteria></FilterCriteriaGroup><ColumnFilterCriteria><DueDates UseEventDates=\'1\' UseAdHocDates=\'0\'><Dates UseDueDate=\'0\' UseReminderDate=\'0\' /><Actions IncludeClosed=\'0\' IsRenewalsOnly=\'1\' IsNonRenewalsOnly=\'1\' /><DueDateResponsibilityOf IsAnyName=\'0\' IsStaff=\'0\' IsSignatory=\'0\' /></DueDates></ColumnFilterCriteria></csw_ListCase></Filtering></Search>";

                var @params = new CommonQueryParameters
                {
                    Filters = new List<CommonQueryParameters.FilterValue>
                    {
                        new CommonQueryParameters.FilterValue {Field = "CountryCode", Operator = "in", Value = "C"},
                        new CommonQueryParameters.FilterValue {Field = "CaseTypeKey", Operator = "notIn", Value = "CT"}
                    }
                };
                var result = CaseSearchHelper.AddXmlFilterCriteriaForFilter(filterCriteria, @params, new FilterableColumnsMap());

                var colFilter = result.SelectSingleNode("Search/Filtering/csw_ListCase/FilterCriteriaGroup/FilterCriteria[@ID='UserColumnFilter']");
                var countryFilter = colFilter?.SelectSingleNode("CountryCodes");
                Assert.Equal("C", countryFilter?.InnerText);
                Assert.Equal("0", countryFilter?.Attributes?["Operator"].Value);

                var caseTypeFilter = colFilter?.SelectSingleNode("CaseTypeKey");
                Assert.Equal("CT", caseTypeFilter?.InnerText);
                Assert.Equal("1", caseTypeFilter?.Attributes?["Operator"].Value);
            }

            [Fact]
            public void AddXmlFilterCriteriaForFilterShouldBeUpdatedCaseKeysInFilterCriteria()
            {
                var filterCriteria = @"<csw_ListCase><FilterCriteriaGroup><FilterCriteria ID='1'><CaseKeys Operator='0'>1,2,3,4</CaseKeys></FilterCriteria></FilterCriteriaGroup></csw_ListCase>";
                CaseSearchHelper.DeSelectedIds = new[] { 1, 2 };
                var request = new SearchExportParams<CaseSearchRequestFilter>
                {
                    DeselectedIds = CaseSearchHelper.DeSelectedIds,
                    Criteria = new CaseSearchRequestFilter
                    {
                        SearchRequest = new List<CaseSearchRequest>
                        {
                            new CaseSearchRequest
                            {
                                CaseKeys = new SearchElement
                                {
                                    Value = "1,2,3,4",
                                    Operator = 0
                                }
                            }
                        }
                    }
                };

                var result = CaseSearchHelper.AddXmlFilterCriteriaForFilter(request.Criteria, filterCriteria, new CommonQueryParameters(), new FilterableColumnsMap());
                var caseKeys = result.SelectSingleNode("//csw_ListCase/FilterCriteriaGroup/FilterCriteria/CaseKeys");
                Assert.Equal("3,4", caseKeys.InnerText);
                Assert.Equal("0", caseKeys.Attributes["Operator"].Value);
            }

            [Fact]
            public void AddXmlFilterCriteriaForFilterShouldReplaceDueDateFilter()
            {
                var filter = new CaseSearchRequestFilter
                {
                    DueDateFilter = new DueDateFilter
                    {
                        DueDates = new DueDates
                        {
                            ImportanceLevel = new DueDateImportanceLevel
                            {
                                From = "10",
                                To = "4"
                            }
                        }
                    }
                };
                const string filterCriteria = "<filterCriteria><csw_ListCase><ColumnFilterCriteria><DueDates UseEventDates=\"0\" UseAdHocDates=\"0\"><ImportanceLevel Operator=\"0\"><From>5</From><To>9</To></ImportanceLevel></DueDates></ColumnFilterCriteria></csw_ListCase></filterCriteria>";
                var r = CaseSearchHelper.AddXmlFilterCriteriaForFilter(filter, filterCriteria, new CommonQueryParameters(), new FilterableColumnsMap());
                var dueDateFrom = r.SelectSingleNode("//filterCriteria/csw_ListCase/ColumnFilterCriteria/DueDates/ImportanceLevel/From");
                var dueDateTo = r.SelectSingleNode("//filterCriteria/csw_ListCase/ColumnFilterCriteria/DueDates/ImportanceLevel/To");
                Assert.Equal("10", dueDateFrom.InnerText);
                Assert.Equal("4", dueDateTo.InnerText);
            }

            [Fact]
            public void AddXmlFilterCriteriaForFilterShouldIncludeCaseKeysInFilterCriteria()
            {
                var filterCriteria = @"<csw_ListCase><FilterCriteriaGroup><FilterCriteria ID='1'> </FilterCriteria></FilterCriteriaGroup></csw_ListCase>";
                var request = new SearchExportParams<CaseSearchRequestFilter>
                {
                    Criteria = new CaseSearchRequestFilter
                    {
                        SearchRequest = new List<CaseSearchRequest>
                        {
                            new CaseSearchRequest
                            {
                                CaseKeys = new SearchElement
                                {
                                    Value = "1,5",
                                    Operator = 1
                                }
                            }
                        }
                    }
                };

                var result = CaseSearchHelper.AddXmlFilterCriteriaForFilter(request.Criteria, filterCriteria, new CommonQueryParameters(), new FilterableColumnsMap());
                var caseKeys = result.SelectSingleNode("//csw_ListCase/FilterCriteriaGroup/FilterCriteria/CaseKeys");
                Assert.Equal("1,5", caseKeys.InnerText);
                Assert.Equal("1", caseKeys.Attributes["Operator"].Value);
            }

            [Fact]
            public void SerializesCaseSearchObjectMethodIntoXml()
            {
                var req = new CaseSearchRequestFilter
                {
                    DueDateFilter = new DueDateFilter
                    {
                        DueDates = new DueDates
                        {
                            UseAdHocDates = 1,
                            UseEventDates = 1,
                            Dates = new Dates
                            {
                                UseDueDate = 1,
                                UseReminderDate = 0,
                                PeriodRange = new PeriodRange
                                {
                                    From = 1,
                                    Operator = "7",
                                    To = 20,
                                    Type = "M"
                                }
                            }
                        }
                    },
                    SearchRequest = new[]
                    {
                        new CaseSearchRequest
                        {
                            CaseReference = new SearchElement {Value = "abc", Operator = 1},
                            OfficialNumber = new OfficialNumberElement
                            {
                                Number = new OfficialNumberNumber {UseNumericSearch = 1, Value = "987"},
                                Operator = 2,
                                TypeKey = "A",
                                UseRelatedCase = 1,
                                UseCurrent = 0
                            }
                        }
                    }
                };

                var @params = new CommonQueryParameters();
                var result = CaseSearchHelper.ConstructXmlFilterCriteria(req, @params, new FilterableColumnsMapResolver.DefaultFilterableColumnMap());

                var caseRefNode = result.SelectSingleNode("csw_ListCase/FilterCriteriaGroup/FilterCriteria/CaseReference");
                Assert.Equal("abc", caseRefNode?.InnerText);
                Assert.Equal("1", caseRefNode?.Attributes?["Operator"].Value);

                var officialNumberNode = result.SelectSingleNode("csw_ListCase/FilterCriteriaGroup/FilterCriteria/OfficialNumber");
                var numberNode = officialNumberNode?.SelectSingleNode("Number");
                Assert.Equal("987", numberNode?.InnerText);
                Assert.Equal("1", numberNode?.Attributes?["UseNumericSearch"].Value);
                Assert.Equal("2", officialNumberNode?.Attributes?["Operator"].Value);
                Assert.Equal("A", officialNumberNode?.SelectSingleNode("TypeKey")?.InnerText);
                Assert.Equal("1", officialNumberNode?.Attributes?["UseRelatedCase"].Value);
                Assert.Equal("0", officialNumberNode?.Attributes?["UseCurrent"].Value);

                var dueDateFilterNode = result.SelectSingleNode("csw_ListCase/ColumnFilterCriteria/DueDates");
                Assert.Equal("1", dueDateFilterNode?.Attributes?["UseEventDates"].Value);
                Assert.Equal("1", dueDateFilterNode?.Attributes?["UseAdHocDates"].Value);

                var datesNode = dueDateFilterNode?.SelectSingleNode("Dates");
                Assert.Equal("1", datesNode?.Attributes?["UseDueDate"].Value);
                Assert.Equal("0", datesNode?.Attributes?["UseReminderDate"].Value);

                var dateRangeNode = datesNode?.SelectSingleNode("PeriodRange");
                Assert.Equal("7", dateRangeNode?.Attributes?["Operator"].Value);
                Assert.Equal("1", dateRangeNode?.SelectSingleNode("From")?.InnerText);
                Assert.Equal("20", dateRangeNode?.SelectSingleNode("To")?.InnerText);
                Assert.Equal("M", dateRangeNode?.SelectSingleNode("Type")?.InnerText);
            }

            [Fact]
            public void SerializesColumnFiltersIntoSecondXmlFilter()
            {
                var req = new CaseSearchRequestFilter
                {
                    SearchRequest = new[]
                    {
                        new CaseSearchRequest {CaseReference = new SearchElement {Value = "abc", Operator = 1}}
                    }
                };

                var @params = new CommonQueryParameters();
                @params.Filters = new List<CommonQueryParameters.FilterValue>
                {
                    new CommonQueryParameters.FilterValue {Field = "CountryCode", Operator = "in", Value = "C"},
                    new CommonQueryParameters.FilterValue {Field = "CaseTypeKey", Operator = "notIn", Value = "CT"},
                    new CommonQueryParameters.FilterValue {Field = "PropertyTypeKey", Operator = "in", Value = "P"},
                    new CommonQueryParameters.FilterValue {Field = "StatusKey", Operator = "notIn", Value = "S"}
                };
                var result = CaseSearchHelper.ConstructXmlFilterCriteria(req, @params, new FilterableColumnsMap());

                var colFilter = result.SelectSingleNode("csw_ListCase/FilterCriteriaGroup/FilterCriteria[@ID='UserColumnFilter']");
                var countryFilter = colFilter?.SelectSingleNode("CountryCodes");
                Assert.Equal("C", countryFilter?.InnerText);
                Assert.Equal("0", countryFilter?.Attributes?["Operator"].Value);

                var caseTypeFilter = colFilter?.SelectSingleNode("CaseTypeKey");
                Assert.Equal("CT", caseTypeFilter?.InnerText);
                Assert.Equal("1", caseTypeFilter?.Attributes?["Operator"].Value);

                var propertyTypeFilter = colFilter?.SelectSingleNode("PropertyTypeKey");
                Assert.Equal("P", propertyTypeFilter?.InnerText);
                Assert.Equal("0", propertyTypeFilter?.Attributes?["Operator"].Value);

                var statusFilter = colFilter?.SelectSingleNode("StatusKey");
                Assert.Equal("S", statusFilter?.InnerText);
                Assert.Equal("1", statusFilter?.Attributes?["Operator"].Value);
            }
        }

        public class AddReplaceDueDateFilterMethod
        {
            readonly string _expectedResult = "<csw_ListCase>\r\n  <ColumnFilterCriteria>\r\n    <DueDates UseEventDates=\"0\" UseAdHocDates=\"0\" />\r\n  </ColumnFilterCriteria>\r\n</csw_ListCase>";
            readonly DueDateFilter _dueDateFilter = new DueDateFilter { DueDates = new DueDates() };

            [Fact]
            public void AddDueDateFilterIfNotExist()
            {
                var filterCriteria = "<csw_ListCase><ColumnFilterCriteria></ColumnFilterCriteria></csw_ListCase>";
                var result = CaseSearchHelper.AddReplaceDueDateFilter(filterCriteria, _dueDateFilter);
                Assert.Equal(_expectedResult, result);
            }

            [Fact]
            public void ReplaceDueDateFilterIfNotExist()
            {
                var filterCriteria = "<csw_ListCase><ColumnFilterCriteria><DueDates><Dates UseReminderDate=\"0\"/></DueDates></ColumnFilterCriteria></csw_ListCase>";
                var result = CaseSearchHelper.AddReplaceDueDateFilter(filterCriteria, _dueDateFilter);
                Assert.Equal(_expectedResult, result);
            }

            [Fact]
            public void ReturnXmlFilterIfDueDateIsNull()
            {
                var filterCriteria = "<csw_ListCase><ColumnFilterCriteria><DueDates><Dates UseReminderDate=\"0\"/></DueDates></ColumnFilterCriteria></csw_ListCase>";
                var result = CaseSearchHelper.AddReplaceDueDateFilter(filterCriteria, null);
                Assert.Equal(filterCriteria, result);
            }
        }

        public class AddStepToRemoveCasesMethod
        {
            [Theory]
            [InlineData(new int[0])]
            [InlineData(null)]
            public void ReturnSameXmlIfNoCasesToBeRemoved(int[] deselectedIds)
            {
                var filterCriteria = "<csw_ListCase></csw_ListCase>";
                var result = CaseSearchHelper.AddStepToFilterCases(deselectedIds, filterCriteria);
                Assert.Equal(filterCriteria, result);
            }

            [Fact]
            public void AddAdditionalStepToRemoveCases()
            {
                var filterCriteria = "<csw_ListCase><ColumnFilterCriteria><FilterCriteriaGroup><FilterCriteria></FilterCriteria></FilterCriteriaGroup></ColumnFilterCriteria></csw_ListCase>";
                var result = CaseSearchHelper.AddStepToFilterCases(new[] { 1, 2 }, filterCriteria);
                var xmlCriteria = XElement.Parse(result);
                var addedStep = xmlCriteria.DescendantsAndSelf("FilterCriteria").Last().ToString();
                Assert.Equal(2, xmlCriteria.DescendantsAndSelf("FilterCriteria").Count());
                Assert.Equal(addedStep, "<FilterCriteria ID=\"2\" BooleanOperator=\"AND\">\r\n  <CaseKeys Operator=\"1\">1,2</CaseKeys>\r\n</FilterCriteria>");
            }
        }
    }
}