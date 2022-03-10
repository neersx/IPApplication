using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Storage;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery.Type;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Delivery.Type
{
    public class SendBillingProfileFileToDmsLocationFacts
    {
        class TestFixture : IFixture<SendBillingProfileFileToDmsLocation>
        {
            public IBillXmlProfileResolver BillXmlProfileResolver { get; } = Substitute.For<IBillXmlProfileResolver>();

            public ISiteControlReader SiteControlReader { get; } = Substitute.For<ISiteControlReader>();

            public IChunkedStreamWriter ChunkStreamWriter { get; } = Substitute.For<IChunkedStreamWriter>();

            public SendBillingProfileFileToDmsLocation Subject { get; }

            public TestFixture()
            {
                var logger = Substitute.For<ILogger<SendBillingProfileFileToDmsLocation>>();

                Subject = new SendBillingProfileFileToDmsLocation(logger, SiteControlReader, BillXmlProfileResolver, ChunkStreamWriter);
            }

            public TestFixture WithSiteControls(Dictionary<string, string> siteControls)
            {
                SiteControlReader.ReadMany<string>(siteControls.Keys.ToArray())
                                 .Returns(siteControls);

                return this;
            }

            public TestFixture WithProfileGenerated(string generatedContent)
            {
                BillXmlProfileResolver.Resolve(Arg.Any<string>(), Arg.Any<BillGenerationRequest>())
                                      .Returns(generatedContent);

                return this;
            }
        }

        [Fact]
        public async Task ShouldCreateBillXmlProfileInDocMgmtDirectory()
        {
            var userIdentityId = Fixture.Integer();
            var docMgmtDirectory = Fixture.String();
            var billXmlProfile = Fixture.String();
            var generatedContent = Fixture.String();

            var request = new BillGenerationRequest
            {
                IsFinalisedBill = true
            };

            var f = new TestFixture()
                    .WithProfileGenerated(generatedContent)
                    .WithSiteControls(new Dictionary<string, string>
                    {
                        { SiteControls.BillXMLProfile, billXmlProfile },
                        { SiteControls.DocMgmtDirectory, docMgmtDirectory }
                    });

            await f.Subject.Deliver(userIdentityId, "en", Guid.Empty, request);

            f.BillXmlProfileResolver.Received(1).Resolve(billXmlProfile, request)
             .IgnoreAwaitForNSubstituteAssertion();

            f.ChunkStreamWriter.Received(1).Write(Path.Combine(docMgmtDirectory, $"{request.OpenItemNo}.xml"), Arg.Any<Stream>())
             .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldNotCreateBilLXmlProfileIfBillIsNotFinalised()
        {
            var userIdentityId = Fixture.Integer();
            var generatedContent = Fixture.String();

            var request = new BillGenerationRequest
            {
                IsFinalisedBill = false
            };

            var f = new TestFixture()
                    .WithProfileGenerated(generatedContent)
                    .WithSiteControls(new Dictionary<string, string>
                    {
                        { SiteControls.BillXMLProfile, Fixture.String() },
                        { SiteControls.DocMgmtDirectory, Fixture.String() }
                    });

            await f.Subject.Deliver(userIdentityId, "en", Guid.Empty, request);

            f.BillXmlProfileResolver.DidNotReceive().Resolve(Arg.Any<string>(), Arg.Any<BillGenerationRequest>())
             .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldRaiseExceptionIfDocMgmtDirectorySiteControlIsEmpty()
        {
            var f = new TestFixture()
                    .WithSiteControls(new Dictionary<string, string>
                    {
                        { SiteControls.BillXMLProfile, Fixture.String() },
                        { SiteControls.DocMgmtDirectory, null }
                    });

            var r = await Assert.ThrowsAsync<ApplicationException>(async () => await f.Subject.EnsureValidSettings());

            Assert.Equal("Both 'DocMgmt Directory' and 'Bill XML Profile' Site Controls must be configured for Bill XML Profile files to be created.", r.Message);
        }
    }
}
