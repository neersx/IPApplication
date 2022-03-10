using System;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery.Type;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Delivery
{
    public class BillDeliveryFacts
    {
        public class OnFinaliseMethod
        {
            readonly IBillDeliveryService _sendToDmsService = Substitute.For<IBillDeliveryService>();
            readonly IBillDeliveryService _otherDeliveryService = Substitute.For<IBillDeliveryService>();

            BillDelivery CreateSubject()
            {
                var factory = Substitute.For<IIndex<BillGenerationType, IBillDeliveryService>>();
                factory[Arg.Any<BillGenerationType>()].Returns(_otherDeliveryService);
                factory[BillGenerationType.GenerateThenSendToDms].Returns(_sendToDmsService);

                var logger = Substitute.For<ILogger<BillDelivery>>();

                return new BillDelivery(logger, factory);
            }

            [Fact]
            public async Task ShouldDeliverToDmsIfBillSaveAsPdfSettingIsGenerateThenSaveToDms()
            {
                var userIdentityId = Fixture.Integer();
                var request = new BillGenerationRequest();
                var settings = new BillingSiteSettings
                {
                    BillSaveAsPdfSetting = BillSaveAsPdfSetting.GenerateThenSaveToDms
                };

                var subject = CreateSubject();

                await subject.OnFinalise(userIdentityId, "en", new BillGenerationTracking(), settings, request);

                _sendToDmsService.Received(1)
                                 .EnsureValidSettings()
                                 .IgnoreAwaitForNSubstituteAssertion();

                _sendToDmsService.Received(1)
                                 .Deliver(userIdentityId, "en", Arg.Any<Guid>(), request)
                                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(BillSaveAsPdfSetting.GenerateOnFinaliseThenAttachToCase)]
            [InlineData(BillSaveAsPdfSetting.GenerateOnPrintThenAttachToCase)]
            public async Task ShouldNotDeliverToDmsIfBillSaveAsPdfSettingIsNotGenerateThenSaveToDms(BillSaveAsPdfSetting billSaveAsPdfSetting)
            {
                var userIdentityId = Fixture.Integer();
                var request = new BillGenerationRequest();
                var settings = new BillingSiteSettings
                {
                    BillSaveAsPdfSetting = billSaveAsPdfSetting
                };

                var subject = CreateSubject();

                await subject.OnFinalise(userIdentityId, "en", new BillGenerationTracking(), settings, request);

                _otherDeliveryService.DidNotReceive()
                                     .EnsureValidSettings()
                                     .IgnoreAwaitForNSubstituteAssertion();

                _otherDeliveryService.DidNotReceive()
                                     .Deliver(userIdentityId, "en", Arg.Any<Guid>(), request)
                                     .IgnoreAwaitForNSubstituteAssertion();

                _sendToDmsService.DidNotReceive()
                                 .EnsureValidSettings()
                                 .IgnoreAwaitForNSubstituteAssertion();

                _sendToDmsService.DidNotReceive()
                                 .Deliver(userIdentityId, "en", Arg.Any<Guid>(), request)
                                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class OnPrintMethod
        {
            readonly IBillDeliveryService _attachToCasesAndNamesService = Substitute.For<IBillDeliveryService>();
            readonly IBillDeliveryService _otherDeliveryService = Substitute.For<IBillDeliveryService>();

            BillDelivery CreateSubject()
            {
                var factory = Substitute.For<IIndex<BillGenerationType, IBillDeliveryService>>();
                factory[Arg.Any<BillGenerationType>()].Returns(_otherDeliveryService);
                factory[BillGenerationType.GenerateThenAttachToCase].Returns(_attachToCasesAndNamesService);

                var logger = Substitute.For<ILogger<BillDelivery>>();

                return new BillDelivery(logger, factory);
            }

            [Theory]
            [InlineData(BillSaveAsPdfSetting.GenerateOnPrintThenAttachToCase)]
            [InlineData(BillSaveAsPdfSetting.GenerateOnFinaliseThenAttachToCase)]
            public async Task ShouldAttachToCaseIfBillSaveAsPdfSettingIsNotGenerateThenSaveToDms(BillSaveAsPdfSetting attachToCasePdfSetting)
            {
                var userIdentityId = Fixture.Integer();
                var request = new BillGenerationRequest();
                var settings = new BillingSiteSettings
                {
                    BillSaveAsPdfSetting = attachToCasePdfSetting
                };

                var subject = CreateSubject();

                await subject.OnPrint(userIdentityId, "en", new BillGenerationTracking(), settings, request);

                _attachToCasesAndNamesService.Received(1)
                                 .EnsureValidSettings()
                                 .IgnoreAwaitForNSubstituteAssertion();

                _attachToCasesAndNamesService.Received(1)
                                 .Deliver(userIdentityId, "en", Arg.Any<Guid>(), request)
                                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(BillSaveAsPdfSetting.GenerateThenSaveToDms)]
            [InlineData(BillSaveAsPdfSetting.NotSet)]
            public async Task ShouldNotAttachToCAseIfBillSaveAsPdfSettingGenerateThenSaveToDmsOrUnset(BillSaveAsPdfSetting billSaveAsPdfSetting)
            {
                var userIdentityId = Fixture.Integer();
                var request = new BillGenerationRequest();
                var settings = new BillingSiteSettings
                {
                    BillSaveAsPdfSetting = billSaveAsPdfSetting
                };

                var subject = CreateSubject();

                await subject.OnPrint(userIdentityId, "en", new BillGenerationTracking(), settings, request);

                _otherDeliveryService.DidNotReceive()
                                     .EnsureValidSettings()
                                     .IgnoreAwaitForNSubstituteAssertion();

                _otherDeliveryService.DidNotReceive()
                                     .Deliver(userIdentityId, "en", Arg.Any<Guid>(), request)
                                     .IgnoreAwaitForNSubstituteAssertion();

                _attachToCasesAndNamesService.DidNotReceive()
                                 .EnsureValidSettings()
                                 .IgnoreAwaitForNSubstituteAssertion();

                _attachToCasesAndNamesService.DidNotReceive()
                                 .Deliver(userIdentityId, "en", Arg.Any<Guid>(), request)
                                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }
    }
}
