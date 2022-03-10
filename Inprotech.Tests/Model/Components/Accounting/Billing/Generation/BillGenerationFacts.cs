
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation.Builders;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Reporting;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Generation
{
    public class BillGenerationFacts
    {
        public class OnFinaliseMethod
        {
            readonly IBillDefinitionBuilder _sendToDmsService = Substitute.For<IBillDefinitionBuilder>();
            readonly IBillDefinitionBuilder _otherDeliveryService = Substitute.For<IBillDefinitionBuilder>();
            readonly IBillPrintDetails _billPrintDetails = Substitute.For<IBillPrintDetails>();
            readonly IReportService _reportService = Substitute.For<IReportService>();

            BillGeneration CreateSubject(params BillPrintDetail[] details)
            {
                var factory = Substitute.For<IIndex<BillGenerationType, IBillDefinitionBuilder>>();
                factory[Arg.Any<BillGenerationType>()].Returns(_otherDeliveryService);
                factory[BillGenerationType.GenerateThenSendToDms].Returns(_sendToDmsService);

                var logger = Substitute.For<ILogger<BillGeneration>>();

                _billPrintDetails.For(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<bool>())
                                 .Returns(x =>
                                 {
                                     return details.Any()
                                         ? details
                                         : new[]
                                         {
                                             new BillPrintDetail
                                             {
                                                 OpenItemNo = (string)x[3],
                                                 BillPrintType = BillPrintType.FinalisedInvoice
                                             }
                                         };
                                 });

                _sendToDmsService.Build(Arg.Any<BillGenerationRequest>(), Arg.Any<BillPrintDetail[]>())
                                 .Returns(x =>
                                 {
                                     var billPrintDetails = (BillPrintDetail[])x[1];

                                     return billPrintDetails.Select(_ => new ReportDefinition
                                     {
                                         ShouldMakeContentModifiable = _.IsPdfModifiable,
                                         ShouldExcludeFromConcatenation = _.ExcludeFromConcatenation,
                                         Parameters = new Dictionary<string, string>()
                                         {
                                             { KnownParameters.BillPrintType, ((int)_.BillPrintType).ToString() }
                                         }
                                     });
                                 });

                _otherDeliveryService.Build(Arg.Any<BillGenerationRequest>(), Arg.Any<BillPrintDetail[]>())
                                     .Returns(x =>
                                     {
                                         var billPrintDetails = (BillPrintDetail[])x[1];

                                         return billPrintDetails.Select(_ => new ReportDefinition
                                         {
                                             ShouldMakeContentModifiable = _.IsPdfModifiable,
                                             ShouldExcludeFromConcatenation = _.ExcludeFromConcatenation,
                                             Parameters = new Dictionary<string, string>()
                                             {
                                                 { KnownParameters.BillPrintType, ((int)_.BillPrintType).ToString() }
                                             }
                                         });
                                     });
                
                return new BillGeneration(logger, factory, _billPrintDetails, _reportService);
            }

            [Fact]
            public async Task ShouldCreateConcatenatedBillIfBillSaveAsPdfIsForDms()
            {
                var userIdentityId = Fixture.Integer();
                var request = new BillGenerationRequest();
                var settings = new BillingSiteSettings
                {
                    BillSaveAsPdfSetting = BillSaveAsPdfSetting.GenerateThenSaveToDms
                };

                var subject = CreateSubject();

                await subject.OnFinalise(userIdentityId, "en", new BillGenerationTracking(), settings, request);

                _otherDeliveryService.DidNotReceive().Build(request, Arg.Any<BillPrintDetail[]>()).IgnoreAwaitForNSubstituteAssertion();

                _sendToDmsService.Received(1).Build(request, Arg.Any<BillPrintDetail[]>()).IgnoreAwaitForNSubstituteAssertion();

                _reportService.Received(1)
                              .Render(Arg.Is<ReportRequest>(_ => _.ShouldConcatenate == true
                                                                 && _.NotificationProcessType == BackgroundProcessType.BillPrint))
                              .IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(BillSaveAsPdfSetting.GenerateOnPrintThenAttachToCase)]
            [InlineData(BillSaveAsPdfSetting.GenerateOnFinaliseThenAttachToCase)]
            public async Task ShouldNotCreateBillsIfBillSaveAsPdfIsNotForDms(BillSaveAsPdfSetting saveAsPdfSetting)
            {
                var userIdentityId = Fixture.Integer();
                var request = new BillGenerationRequest();
                var settings = new BillingSiteSettings
                {
                    BillSaveAsPdfSetting = saveAsPdfSetting
                };

                var subject = CreateSubject();

                await subject.OnFinalise(userIdentityId, "en", new BillGenerationTracking(), settings, request);

                _otherDeliveryService.DidNotReceive().Build(request, Arg.Any<BillPrintDetail[]>()).IgnoreAwaitForNSubstituteAssertion();

                _sendToDmsService.DidNotReceive().Build(request, Arg.Any<BillPrintDetail[]>()).IgnoreAwaitForNSubstituteAssertion();

                _reportService.DidNotReceive().Render(Arg.Any<ReportRequest>()).IgnoreAwaitForNSubstituteAssertion();
            }
            
            [Fact]
            public async Task ShouldNotPrintCopiesToIfIndicated()
            {
                var userIdentityId = Fixture.Integer();
                
                var request = new BillGenerationRequest
                {
                    ShouldNotPrintCopyTo = true
                };

                var settings = new BillingSiteSettings
                {
                    BillSaveAsPdfSetting = BillSaveAsPdfSetting.GenerateThenSaveToDms
                };

                var subject = CreateSubject(
                                            new BillPrintDetail
                                            {
                                                BillPrintType = BillPrintType.CopyToInvoice
                                            }, new BillPrintDetail
                                            {
                                                BillPrintType = BillPrintType.FinalisedInvoice
                                            });

                await subject.OnFinalise(userIdentityId, "en", new BillGenerationTracking(), settings, request);

                _otherDeliveryService.DidNotReceive().Build(request, Arg.Any<BillPrintDetail[]>()).IgnoreAwaitForNSubstituteAssertion();

                _sendToDmsService.Received(1).Build(request, Arg.Is<BillPrintDetail[]>(_ => _.Single().BillPrintType == BillPrintType.FinalisedInvoice))
                                 .IgnoreAwaitForNSubstituteAssertion();

                _reportService.Received(1)
                              .Render(Arg.Is<ReportRequest>(_ => _.ShouldConcatenate == true
                                                                 && _.NotificationProcessType == BackgroundProcessType.BillPrint))
                              .IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ShouldReturnBillGenerationStateFromReportService(bool reportServiceSuccessFailureState)
            {
                var userIdentityId = Fixture.Integer();
                var request = new BillGenerationRequest();

                var settings = new BillingSiteSettings
                {
                    BillSaveAsPdfSetting = BillSaveAsPdfSetting.GenerateThenSaveToDms
                };

                _reportService.Render(Arg.Any<ReportRequest>()).Returns(reportServiceSuccessFailureState); 

                var subject = CreateSubject();

                var r = await subject.OnFinalise(userIdentityId, "en", new BillGenerationTracking(), settings, request);

                Assert.Equal(reportServiceSuccessFailureState, r);
            }
        }

        public class OnPrintMethod
        {
            readonly IBillDefinitionBuilder _printAndAttachService = Substitute.For<IBillDefinitionBuilder>();
            readonly IBillDefinitionBuilder _generateOnlyService = Substitute.For<IBillDefinitionBuilder>();
            readonly IBillPrintDetails _billPrintDetails = Substitute.For<IBillPrintDetails>();
            readonly IReportService _reportService = Substitute.For<IReportService>();

            BillGeneration CreateSubject(params BillPrintDetail[] details)
            {
                var factory = Substitute.For<IIndex<BillGenerationType, IBillDefinitionBuilder>>();
                factory[Arg.Any<BillGenerationType>()].Returns(_generateOnlyService);
                factory[BillGenerationType.GenerateThenAttachToCase].Returns(_printAndAttachService);

                var logger = Substitute.For<ILogger<BillGeneration>>();

                _billPrintDetails.For(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<bool>())
                                 .Returns(x =>
                                 {
                                     return details.Any()
                                         ? details
                                         : new[]
                                         {
                                             new BillPrintDetail
                                             {
                                                 OpenItemNo = (string)x[3],
                                                 BillPrintType = BillPrintType.FinalisedInvoice
                                             }
                                         };
                                 });

                _printAndAttachService.Build(Arg.Any<BillGenerationRequest>(), Arg.Any<BillPrintDetail[]>())
                                 .Returns(x =>
                                 {
                                     var billPrintDetails = (BillPrintDetail[])x[1];

                                     return billPrintDetails.Select(_ => new ReportDefinition
                                     {
                                         ShouldMakeContentModifiable = _.IsPdfModifiable,
                                         ShouldExcludeFromConcatenation = _.ExcludeFromConcatenation,
                                         Parameters = new Dictionary<string, string>()
                                         {
                                             { KnownParameters.BillPrintType, ((int)_.BillPrintType).ToString() }
                                         }
                                     });
                                 });

                _generateOnlyService.Build(Arg.Any<BillGenerationRequest>(), Arg.Any<BillPrintDetail[]>())
                                     .Returns(x =>
                                     {
                                         var billPrintDetails = (BillPrintDetail[])x[1];

                                         return billPrintDetails.Select(_ => new ReportDefinition
                                         {
                                             ShouldMakeContentModifiable = _.IsPdfModifiable,
                                             ShouldExcludeFromConcatenation = _.ExcludeFromConcatenation,
                                             Parameters = new Dictionary<string, string>()
                                             {
                                                 { KnownParameters.BillPrintType, ((int)_.BillPrintType).ToString() }
                                             }
                                         });
                                     });
                
                return new BillGeneration(logger, factory, _billPrintDetails, _reportService);
            }

            [Theory]
            [InlineData(BillSaveAsPdfSetting.GenerateOnPrintThenAttachToCase)]
            [InlineData(BillSaveAsPdfSetting.GenerateOnFinaliseThenAttachToCase)]
            public async Task ShouldCreateConcatenatedBillIfBillSaveAsPdfIsToLinkToCasesAndNames(BillSaveAsPdfSetting saveAsPdfSetting)
            {
                var userIdentityId = Fixture.Integer();
                var request = new BillGenerationRequest();
                var settings = new BillingSiteSettings
                {
                    BillSaveAsPdfSetting = saveAsPdfSetting
                };

                var subject = CreateSubject();

                await subject.OnPrint(userIdentityId, "en", new BillGenerationTracking(), settings, request);

                _generateOnlyService.DidNotReceive().Build(request, Arg.Any<BillPrintDetail[]>()).IgnoreAwaitForNSubstituteAssertion();

                _printAndAttachService.Received(1).Build(request, Arg.Any<BillPrintDetail[]>()).IgnoreAwaitForNSubstituteAssertion();

                _reportService.Received(1)
                              .Render(Arg.Is<ReportRequest>(_ => _.ShouldConcatenate == true
                                                                 && _.NotificationProcessType == BackgroundProcessType.BillPrint))
                              .IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(BillSaveAsPdfSetting.GenerateThenSaveToDms)]
            [InlineData(BillSaveAsPdfSetting.NotSet)]
            public async Task ShouldGenerateWithoutSavingWhenBillSaveAsPdfIsNotToLinkToCasesAndNames(BillSaveAsPdfSetting saveAsPdfSetting)
            {
                var userIdentityId = Fixture.Integer();
                var request = new BillGenerationRequest();
                var settings = new BillingSiteSettings
                {
                    BillSaveAsPdfSetting = saveAsPdfSetting
                };

                var subject = CreateSubject();

                await subject.OnPrint(userIdentityId, "en", new BillGenerationTracking(), settings, request);

                _generateOnlyService.Received(1).Build(request, Arg.Any<BillPrintDetail[]>()).IgnoreAwaitForNSubstituteAssertion();

                _printAndAttachService.DidNotReceive().Build(request, Arg.Any<BillPrintDetail[]>()).IgnoreAwaitForNSubstituteAssertion();

                _reportService.Received(1)
                              .Render(Arg.Is<ReportRequest>(_ => _.ShouldConcatenate == true
                                                                 && _.NotificationProcessType == BackgroundProcessType.BillPrint))
                              .IgnoreAwaitForNSubstituteAssertion();
            }
            
            [Fact]
            public async Task ShouldNotPrintCopiesToIfIndicated()
            {
                var userIdentityId = Fixture.Integer();
                
                var request = new BillGenerationRequest
                {
                    ShouldNotPrintCopyTo = true
                };

                var settings = new BillingSiteSettings
                {
                    BillSaveAsPdfSetting = BillSaveAsPdfSetting.GenerateThenSaveToDms
                };

                var subject = CreateSubject(
                                            new BillPrintDetail
                                            {
                                                BillPrintType = BillPrintType.CopyToInvoice
                                            }, new BillPrintDetail
                                            {
                                                BillPrintType = BillPrintType.FinalisedInvoice
                                            });

                await subject.OnPrint(userIdentityId, "en", new BillGenerationTracking(), settings, request);

                _printAndAttachService.DidNotReceive().Build(request, Arg.Any<BillPrintDetail[]>()).IgnoreAwaitForNSubstituteAssertion();

                _generateOnlyService.Received(1).Build(request, Arg.Is<BillPrintDetail[]>(_ => _.Single().BillPrintType == BillPrintType.FinalisedInvoice))
                                 .IgnoreAwaitForNSubstituteAssertion();

                _reportService.Received(1)
                              .Render(Arg.Is<ReportRequest>(_ => _.ShouldConcatenate == true
                                                                 && _.NotificationProcessType == BackgroundProcessType.BillPrint))
                              .IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ShouldReturnBillGenerationStateFromReportService(bool reportServiceSuccessFailureState)
            {
                var userIdentityId = Fixture.Integer();
                var request = new BillGenerationRequest();

                var settings = new BillingSiteSettings
                {
                    BillSaveAsPdfSetting = BillSaveAsPdfSetting.GenerateThenSaveToDms
                };

                _reportService.Render(Arg.Any<ReportRequest>()).Returns(reportServiceSuccessFailureState); 

                var subject = CreateSubject();

                var r = await subject.OnPrint(userIdentityId, "en", new BillGenerationTracking(), settings, request);

                Assert.Equal(reportServiceSuccessFailureState, r);
            }
        }

    }
}
