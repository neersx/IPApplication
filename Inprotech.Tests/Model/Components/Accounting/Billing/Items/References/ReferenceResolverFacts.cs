using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.References;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.References
{
    public class ReferenceResolverFacts : FactBase
    {
        readonly IDocItemRunner _docItemRunner = Substitute.For<IDocItemRunner>();

        ReferenceResolver CreateSubject(Dictionary<string, string> siteControls = null, Dictionary<string, string> dataItemReturns = null)
        {
            var siteControlReader = Substitute.For<ISiteControlReader>();
            siteControlReader.ReadMany<string>(Arg.Any<string[]>())
                             .Returns(siteControls ?? new Dictionary<string, string>());

            foreach (var dataItemReturn in dataItemReturns ?? new Dictionary<string, string>())
            {
                _docItemRunner.Run(dataItemReturn.Key, Arg.Any<IDictionary<string, object>>())
                              .Returns(ScalarValuedDataSet(dataItemReturn.Value));
            }

            return new ReferenceResolver(Db, _docItemRunner, siteControlReader);
        }

        static DataSet ScalarValuedDataSet(object value)
        {
            var dataSet = new DataSet();
            var dataTable = new DataTable();
            dataTable.Columns.Add(new DataColumn());
            dataTable.Rows.Add(value);

            dataSet.Tables.Add(dataTable);
            return dataSet;
        }

        [Fact]
        public async Task ShouldReturnReferenceTextForSingleCaseBillIfSiteControlConfigured()
        {
            var identityId = Fixture.Integer();
            var culture = Fixture.String();
            var openItemNo = Fixture.String();
            var caseId = new[] { new Case { Irn = Fixture.String() }.In(Db).Id };
            var debtorId = Fixture.Integer();
            var languageId = Fixture.Integer();
            var useRenewalDebtor = Fixture.Boolean();

            var billRefSingleDataItem = Fixture.String();
            var billRefResultOfDataItemExecution = Fixture.String();

            var subject = CreateSubject(new Dictionary<string, string>
                                        {
                                            { SiteControls.BillRef_Single, billRefSingleDataItem }
                                        },
                                        new Dictionary<string, string>
                                        {
                                            { billRefSingleDataItem, billRefResultOfDataItemExecution }
                                        });

            var r = await subject.Resolve(identityId, culture, caseId, languageId, useRenewalDebtor, debtorId, openItemNo);

            Assert.Null(r.StatementText);
            Assert.Equal(billRefResultOfDataItemExecution, r.ReferenceText);
        }

        [Fact]
        public async Task ShouldReturnStatementRefTextForSingleCaseBillIfSiteControlConfigured()
        {
            var identityId = Fixture.Integer();
            var culture = Fixture.String();
            var openItemNo = Fixture.String();
            var caseId = new[] { new Case { Irn = Fixture.String() }.In(Db).Id };
            var debtorId = Fixture.Integer();
            var languageId = Fixture.Integer();
            var useRenewalDebtor = Fixture.Boolean();

            var statementRefDataItem = Fixture.String();
            var statementRefResultOfDataItemExecution = Fixture.String();

            var subject = CreateSubject(new Dictionary<string, string>
                                        {
                                            { SiteControls.Statement_Single, statementRefDataItem }
                                        },
                                        new Dictionary<string, string>
                                        {
                                            { statementRefDataItem, statementRefResultOfDataItemExecution }
                                        });

            var r = await subject.Resolve(identityId, culture, caseId, languageId, useRenewalDebtor, debtorId, openItemNo);

            Assert.Null(r.ReferenceText);
            Assert.Equal(statementRefResultOfDataItemExecution, r.StatementText);
        }

        [Fact]
        public async Task ShouldReturnReferenceTextConcatenatedWithNewLineForMultiCaseBill()
        {
            var identityId = Fixture.Integer();
            var culture = Fixture.String();
            var openItemNo = Fixture.String();
            var caseIds = new[]
            {
                new Case { Irn = Fixture.String() }.In(Db).Id,
                new Case { Irn = Fixture.String() }.In(Db).Id
            };
            var debtorId = Fixture.Integer();
            var languageId = Fixture.Integer();
            var useRenewalDebtor = Fixture.Boolean();

            var billRef1DataItem = Fixture.String();
            var billRef1DataItemExecutionResult = Fixture.String();

            var billRef2DataItem = Fixture.String();
            var billRef2DataItemExecutionResult = Fixture.String();

            var subject = CreateSubject(new Dictionary<string, string>
                                        {
                                            { SiteControls.BillRef_Multi0, billRef1DataItem },
                                            { SiteControls.BillRef_Multi9, billRef2DataItem }
                                        },
                                        new Dictionary<string, string>
                                        {
                                            { billRef1DataItem, billRef1DataItemExecutionResult },
                                            { billRef2DataItem, billRef2DataItemExecutionResult }
                                        });

            var r = await subject.Resolve(identityId, culture, caseIds, languageId, useRenewalDebtor, debtorId, openItemNo);

            Assert.Null(r.StatementText);
            Assert.Equal($"{billRef1DataItemExecutionResult}{Environment.NewLine}{billRef2DataItemExecutionResult}", r.ReferenceText);
        }

        [Fact]
        public async Task ShouldGetReferenceTextWithMainCaseAsEntryPointForFirstAndLastThenAllInTheMiddle()
        {
            var identityId = Fixture.Integer();
            var culture = Fixture.String();
            var openItemNo = Fixture.String();
            var case1 = new Case { Irn = "1-" + Fixture.String() }.In(Db);
            var case2 = new Case { Irn = "2-" + Fixture.String() }.In(Db);
            var caseIds = new[] { case1.Id, case2.Id };
            var debtorId = Fixture.Integer();
            var languageId = Fixture.Integer();
            var useRenewalDebtor = Fixture.Boolean();

            var billRef1DataItem = "1-" + Fixture.String();
            var billRef1DataItemExecutionResult = Fixture.String();

            var billRef2DataItem = "2-" + Fixture.String();
            var billRef2DataItemExecutionResult = Fixture.String();

            var billRef3DataItem = "3-" + Fixture.String();
            var billRef3DataItemExecutionResult = Fixture.String();

            var billRef9DataItem = "9-" + Fixture.String();
            var billRef9DataItemExecutionResult = Fixture.String();

            var subject = CreateSubject(new Dictionary<string, string>
                                        {
                                            { SiteControls.BillRef_Multi0, billRef1DataItem },
                                            { SiteControls.BillRef_Multi1, billRef2DataItem },
                                            { SiteControls.BillRef_Multi2, billRef3DataItem },
                                            { SiteControls.BillRef_Multi9, billRef9DataItem }
                                        },
                                        new Dictionary<string, string>
                                        {
                                            { billRef1DataItem, billRef1DataItemExecutionResult },
                                            { billRef2DataItem, billRef2DataItemExecutionResult },
                                            { billRef3DataItem, billRef3DataItemExecutionResult },
                                            { billRef9DataItem, billRef9DataItemExecutionResult }
                                        });

            var r = await subject.Resolve(identityId, culture, caseIds, languageId, useRenewalDebtor, debtorId, openItemNo);

            Assert.Null(r.StatementText);
            Assert.Equal(billRef1DataItemExecutionResult + Environment.NewLine +
                         billRef2DataItemExecutionResult + Environment.NewLine +
                         billRef3DataItemExecutionResult + Environment.NewLine +
                         billRef9DataItemExecutionResult, r.ReferenceText);

            // entry point should contain only the main case irn
            _docItemRunner.Received(1)
                          .Run(billRef1DataItem, Arg.Is<IDictionary<string, object>>(x => Equals(x["gstrEntryPoint"], case1.Irn)));

            // entry point should contain csv of all cases
            _docItemRunner.Received(1)
                          .Run(billRef2DataItem, Arg.Is<IDictionary<string, object>>(x => Equals(x["gstrEntryPoint"], case1.Irn + "," + case2.Irn)));

            // entry point should contain csv of all cases
            _docItemRunner.Received(1)
                          .Run(billRef3DataItem, Arg.Is<IDictionary<string, object>>(x => Equals(x["gstrEntryPoint"], case1.Irn + "," + case2.Irn)));

            // entry point should contain only the main case irn
            _docItemRunner.Received(1)
                          .Run(billRef9DataItem, Arg.Is<IDictionary<string, object>>(x => Equals(x["gstrEntryPoint"], case1.Irn)));
        }

        [Fact]
        public async Task ShouldReturnStatementRefTextConcatenatedWithNewLineForMultiCaseBill()
        {
            var identityId = Fixture.Integer();
            var culture = Fixture.String();
            var openItemNo = Fixture.String();
            var caseIds = new[]
            {
                new Case { Irn = Fixture.String() }.In(Db).Id,
                new Case { Irn = Fixture.String() }.In(Db).Id
            };
            var debtorId = Fixture.Integer();
            var languageId = Fixture.Integer();
            var useRenewalDebtor = Fixture.Boolean();

            var statementRef1DataItem = Fixture.String();
            var statementRef1DataItemExecutionResult = Fixture.String();

            var statementRef2DataItem = Fixture.String();
            var statementRef2DataItemExecutionResult = Fixture.String();

            var subject = CreateSubject(new Dictionary<string, string>
                                        {
                                            { SiteControls.Statement_Multi0, statementRef1DataItem },
                                            { SiteControls.Statement_Multi9, statementRef2DataItem }
                                        },
                                        new Dictionary<string, string>
                                        {
                                            { statementRef1DataItem, statementRef1DataItemExecutionResult },
                                            { statementRef2DataItem, statementRef2DataItemExecutionResult }
                                        });

            var r = await subject.Resolve(identityId, culture, caseIds, languageId, useRenewalDebtor, debtorId, openItemNo);

            Assert.Null(r.ReferenceText);
            Assert.Equal($"{statementRef1DataItemExecutionResult}{Environment.NewLine}{statementRef2DataItemExecutionResult}", r.StatementText);
        }

        [Fact]
        public async Task ShouldGetStatementRefTextWithMainCaseAsEntryPointForFirstAndLastThenAllInTheMiddle()
        {
            var identityId = Fixture.Integer();
            var culture = Fixture.String();
            var openItemNo = Fixture.String();
            var case1 = new Case { Irn = "1-" + Fixture.String() }.In(Db);
            var case2 = new Case { Irn = "2-" + Fixture.String() }.In(Db);
            var caseIds = new[] { case1.Id, case2.Id };
            var debtorId = Fixture.Integer();
            var languageId = Fixture.Integer();
            var useRenewalDebtor = Fixture.Boolean();

            var statementRef1DataItem = "1-" + Fixture.String();
            var statementRef1DataItemExecutionResult = Fixture.String();

            var statementRef2DataItem = "2-" + Fixture.String();
            var statementRef2DataItemExecutionResult = Fixture.String();

            var statementRef3DataItem = "3-" + Fixture.String();
            var statementRef3DataItemExecutionResult = Fixture.String();

            var statementRef9DataItem = "9-" + Fixture.String();
            var statementRef9DataItemExecutionResult = Fixture.String();

            var subject = CreateSubject(new Dictionary<string, string>
                                        {
                                            { SiteControls.Statement_Multi0, statementRef1DataItem },
                                            { SiteControls.Statement_Multi1, statementRef2DataItem },
                                            { SiteControls.Statement_Multi2, statementRef3DataItem },
                                            { SiteControls.Statement_Multi9, statementRef9DataItem }
                                        },
                                        new Dictionary<string, string>
                                        {
                                            { statementRef1DataItem, statementRef1DataItemExecutionResult },
                                            { statementRef2DataItem, statementRef2DataItemExecutionResult },
                                            { statementRef3DataItem, statementRef3DataItemExecutionResult },
                                            { statementRef9DataItem, statementRef9DataItemExecutionResult }
                                        });

            var r = await subject.Resolve(identityId, culture, caseIds, languageId, useRenewalDebtor, debtorId, openItemNo);

            Assert.Null(r.ReferenceText);
            Assert.Equal(statementRef1DataItemExecutionResult + Environment.NewLine +
                         statementRef2DataItemExecutionResult + Environment.NewLine +
                         statementRef3DataItemExecutionResult + Environment.NewLine +
                         statementRef9DataItemExecutionResult, r.StatementText);

            // entry point should contain only the main case irn
            _docItemRunner.Received(1)
                          .Run(statementRef1DataItem, Arg.Is<IDictionary<string, object>>(x => Equals(x["gstrEntryPoint"], case1.Irn)));

            // entry point should contain csv of all cases
            _docItemRunner.Received(1)
                          .Run(statementRef2DataItem, Arg.Is<IDictionary<string, object>>(x => Equals(x["gstrEntryPoint"], case1.Irn + "," + case2.Irn)));

            // entry point should contain csv of all cases
            _docItemRunner.Received(1)
                          .Run(statementRef3DataItem, Arg.Is<IDictionary<string, object>>(x => Equals(x["gstrEntryPoint"], case1.Irn + "," + case2.Irn)));

            // entry point should contain only the main case irn
            _docItemRunner.Received(1)
                          .Run(statementRef9DataItem, Arg.Is<IDictionary<string, object>>(x => Equals(x["gstrEntryPoint"], case1.Irn)));
        }
    }
  
}