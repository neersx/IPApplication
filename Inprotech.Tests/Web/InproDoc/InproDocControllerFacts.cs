using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Integration.Analytics;
using Inprotech.Tests.Extensions;
using Inprotech.Web.InproDoc;
using Inprotech.Web.InproDoc.Config;
using Inprotech.Web.InproDoc.Dto;
using InprotechKaizen.Model.Components.DocumentGeneration;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor;
using InprotechKaizen.Model.Components.DocumentGeneration.Services;
using NSubstitute;
using Xunit;
using DocItem = Inprotech.Web.InproDoc.Dto.DocItem;
using Document = Inprotech.Web.InproDoc.Dto.Document;

namespace Inprotech.Tests.Web.InproDoc
{
    public class InproDocControllerFacts : FactBase
    {
        public class VerifyMappings : FactBase
        {
            readonly InproDocFixture _fixture;

            public VerifyMappings()
            {
                _fixture = new InproDocFixture();
            }

            [Fact]
            public async Task DocItemsProperlyMapped()
            {
                var di = new ReferencedDataItem
                {
                    ItemKey = Fixture.Integer(),
                    ItemName = Fixture.String(),
                    ItemDescription = Fixture.String(),
                    EntryPointUsage = Fixture.Integer()
                };

                _fixture.DocItemCommand.ListDocItems(null).ReturnsForAnyArgs(new List<ReferencedDataItem> {di});

                var result = (await _fixture.Subject.ListDocItems()).ToArray();

                Assert.Single(result);

                var first = result.First();
                Assert.Equal(di.ItemKey, first.ItemKey);
                Assert.Equal(di.ItemName, first.ItemName);
                Assert.Equal(di.ItemDescription, first.ItemDescription);
                Assert.Equal(di.EntryPointUsage, first.EntryPointUsage);
            }

            [Fact]
            public async Task DoesNotPublishMessageToBusIfNoHeadersPresent()
            {
                var _ = (await _fixture.Subject.ListDocItems()).ToArray();

                _fixture.Bus.DidNotReceive().PublishAsync(Arg.Any<TransactionalAnalyticsMessage>())
                        .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task PublishesToBusIfVersionAndSessionIdHeadersPresent()
            {
                var version = Fixture.String();
                var sessionId = Fixture.String();
                _fixture.Subject.Request.Headers.Add("x-inprodoc-version", version);
                _fixture.Subject.Request.Headers.Add("x-inprodoc-sessionId", sessionId);

                var _ = (await _fixture.Subject.ListDocItems()).ToArray();

                _fixture.Bus.Received(1)
                        .PublishAsync(Arg.Is<TransactionalAnalyticsMessage>(i => i.EventType == TransactionalEventTypes.InprodocAdHocGeneration && i.Value == $"{version}^{sessionId}"))
                        .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public void EntryPointsAreReturnedWithoutChange()
            {
                var ep = new EntryPoint();

                _fixture.PassthruManager.GetEntryPoints().Returns(new List<EntryPoint> {ep});

                var result = _fixture.PassthruManager.GetEntryPoints().ToArray();

                Assert.Single(result);
                Assert.Equal(ep, result.First());
            }

            [Fact]
            public async Task ExecuteDocItemsProperlyMapped()
            {
                var req = Fixture.Object<ItemProcessorRequest>();
                req.Fields = new List<Field> {Fixture.Object<Field>()};
                req.DocItem = Fixture.Object<DocItem>();

                var spRetval = Fixture.Object<ItemProcessor>();
                spRetval.Exception = new Exception("something");
                spRetval.TableResultSets = new List<TableResultSet>();

                _fixture.DocItemsRunner.Execute(null).ReturnsForAnyArgs(new List<ItemProcessor> {spRetval});

                var r = (await _fixture.Subject.ExecuteDocItems(new[] {req})).ToArray();

                _fixture.DocItemsRunner
                        .Received(1)
                        .Execute(Arg.Do<IList<ItemProcessor>>(x =>
                        {
                            var first = x.First();

                            Assert.Equal(req.ID, first.ID);
                            Assert.Equal(req.Fields.Count, first.Fields.Count);
                            Assert.Equal(req.Fields[0], first.Fields[0]);

                            Assert.Equal(req.DocItem.ItemKey, first.ReferencedDataItem.ItemKey);
                            Assert.Equal(req.DocItem.ItemName, first.ReferencedDataItem.ItemName);
                            Assert.Equal(req.DocItem.ItemDescription, first.ReferencedDataItem.ItemDescription);
                            Assert.Equal(req.DocItem.EntryPointUsage, first.ReferencedDataItem.EntryPointUsage);

                            Assert.Equal(req.Separator, first.Separator);
                            Assert.Equal(req.Parameters, req.Parameters);
                            Assert.Equal(req.EntryPointValue, req.EntryPointValue);
                        }));

                Assert.Equal(spRetval.ID, r.First().ID);
                Assert.Equal(spRetval.DateStyle, r.First().DateStyle);
                Assert.Equal(spRetval.EmptyValue, r.First().EmptyValue);
                Assert.Equal(spRetval.TableResultSets.Count, r.First().TableResultSets.Count);
                Assert.Equal(spRetval.Exception.Message, r.First().Exception);
            }

            [Fact]
            public void ListOfDocsProperlyMapped()
            {
                var doc = Fixture.Object<Document>();

                _fixture.DocumentCommand.ListDocuments(null, 0, 0, null).ReturnsForAnyArgs(new List<Document> {doc});

                var result = _fixture.Subject.ListDocumentsByType(new DocumentListRequest());

                Assert.Single(result.Documents);

                var first = result.Documents.First();

                Assert.Equal(doc.DocumentKey, first.DocumentKey);
                Assert.Equal(doc.DocumentDescription, first.DocumentDescription);
                Assert.Equal(doc.DocumentCode, first.DocumentCode);
                Assert.Equal(doc.Template, first.Template);
                Assert.Equal(doc.PlaceOnHold, first.PlaceOnHold);
                Assert.Equal(doc.DeliveryMethodKey, first.DeliveryMethodKey);
                Assert.Equal(doc.DeliveryMethodDescription, first.DeliveryMethodDescription);
                Assert.Equal(doc.DefaultFilePath, first.DefaultFilePath);
                Assert.Equal(doc.FileDestinationSP, first.FileDestinationSP);
                Assert.Equal(doc.DocumentType, first.DocumentType);
                Assert.Equal(doc.SourceFile, first.SourceFile);
                Assert.Equal(doc.CorrespondenceTypeKey, first.CorrespondenceTypeKey);
                Assert.Equal(doc.CorrespondenceTypeDescription, first.CorrespondenceTypeDescription);
                Assert.Equal(doc.CoveringLetterKey, first.CoveringLetterKey);
                Assert.Equal(doc.CoveringLetterDescription, first.CoveringLetterDescription);
                Assert.Equal(doc.EnvelopeKey, first.EnvelopeKey);
                Assert.Equal(doc.EnvelopeDescription, first.EnvelopeDescription);
                Assert.Equal(doc.ForPrimeCasesOnly, first.ForPrimeCasesOnly);
                Assert.Equal(doc.GenerateAsANSI, first.GenerateAsANSI);
                Assert.Equal(doc.MultiCase, first.MultiCase);
                Assert.Equal(doc.CopiesAllowed, first.CopiesAllowed);
                Assert.Equal(doc.NbExtraCopies, first.NbExtraCopies);
                Assert.Equal(doc.SingleCaseLetterKey, first.SingleCaseLetterKey);
                Assert.Equal(doc.SingleCaseLetterDescription, first.SingleCaseLetterDescription);
                Assert.Equal(doc.AddAttachment, first.AddAttachment);
                Assert.Equal(doc.ActivityTypeKey, first.ActivityTypeKey);
                Assert.Equal(doc.ActivityTypeDescription, first.ActivityTypeDescription);
                Assert.Equal(doc.ActivityCategoryKey, first.ActivityCategoryKey);
                Assert.Equal(doc.ActivityCategoryDescription, first.ActivityCategoryDescription);
                Assert.Equal(doc.InstructionTypeKey, first.InstructionTypeKey);
                Assert.Equal(doc.InstructionTypeDescription, first.InstructionTypeDescription);
                Assert.Equal(doc.CountryCode, first.CountryCode);
                Assert.Equal(doc.CountryDescription, first.CountryDescription);
                Assert.Equal(doc.PropertyType, first.PropertyType);
                Assert.Equal(doc.PropertyTypeDescription, first.PropertyTypeDescription);
                Assert.Equal(doc.UsedByCases, first.UsedByCases);
                Assert.Equal(doc.UsedByNames, first.UsedByNames);
                Assert.Equal(doc.UsedByTimeAndBilling, first.UsedByTimeAndBilling);
                Assert.Equal(doc.IsInproDocOnlyTemplate, first.IsInproDocOnlyTemplate);
                Assert.Equal(doc.IsDGLibOnlyTemplate, first.IsDGLibOnlyTemplate);
                Assert.Equal(doc.EntryPointTypeKey, first.EntryPointTypeKey);
                Assert.Equal(doc.EntryPointTypeDescription, first.EntryPointTypeDescription);
                Assert.Equal(doc.AllFieldsLoaded, first.AllFieldsLoaded);
            }

            [Fact]
            public void ListOfDocsReadsSiteControls()
            {
                _fixture.SiteControls.Read<string>(SiteControls.InproDocLocalTemplates).Returns("local");
                _fixture.SiteControls.Read<string>(SiteControls.InproDocNetworkTemplates).Returns("network");

                var result = _fixture.Subject.ListDocumentsByType(new DocumentListRequest {DocumentType = DocumentType.Word});

                Assert.Equal("local", result.LocalTemplatesPath);
                Assert.Equal("network", result.NetworkTemplatesPath);
            }

            [Fact]
            public void RowsReturnedModeGetsFixed()
            {
                // test single

                var reqSingle = new[]
                {
                    new ItemProcessorRequest
                    {
                        Fields = new List<Field>
                        {
                            new Field
                            {
                                RowsReturnedMode = RowsReturnedMode.Single
                            }
                        }
                    }
                };

                _fixture.Subject.ExecuteDocItems(reqSingle);
                _fixture.DocItemsRunner.Received(1).Execute(Arg.Is<IList<ItemProcessor>>(x => x.First().RowsReturnedMode == RowsReturnedMode.Single));

                _fixture.DocItemsRunner.ClearReceivedCalls();

                // test multi

                var reqMulti = new[]
                {
                    new ItemProcessorRequest
                    {
                        Fields = new List<Field>
                        {
                            new Field
                            {
                                RowsReturnedMode = RowsReturnedMode.Multiple
                            }
                        }
                    }
                };

                _fixture.Subject.ExecuteDocItems(reqMulti);
                _fixture.DocItemsRunner.Received(1).Execute(Arg.Is<IList<ItemProcessor>>(x => x.First().RowsReturnedMode == RowsReturnedMode.Multiple));
            }
        }

        class InproDocFixture : IFixture<InproDocController>
        {
            public InproDocFixture()
            {
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                PassthruManager = Substitute.For<IPassThruManager>();
                DocItemsRunner = Substitute.For<IRunDocItemsManager>();
                SiteControls = Substitute.For<ISiteControlReader>();
                DocItemCommand = Substitute.For<IDocItemCommand>();
                DocumentCommand = Substitute.For<IDocumentService>();

                Bus = Substitute.For<IBus>();
                
                Subject = new InproDocController(PassthruManager,
                                                 DocItemsRunner,
                                                 SiteControls,
                                                 preferredCultureResolver,
                                                 DocItemCommand,
                                                 DocumentCommand,
                                                 Bus)
                {
                    Request = new HttpRequestMessage()
                };
            }

            public IBus Bus { get; }
            public IPassThruManager PassthruManager { get; }
            public IRunDocItemsManager DocItemsRunner { get; }
            public ISiteControlReader SiteControls { get; }
            public IDocItemCommand DocItemCommand { get; }
            public IDocumentService DocumentCommand { get; }

            public InproDocController Subject { get; }
        }
    }
}