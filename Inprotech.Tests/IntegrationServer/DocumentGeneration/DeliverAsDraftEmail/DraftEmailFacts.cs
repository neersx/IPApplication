using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Contracts.DocItems;
using Inprotech.IntegrationServer.DocumentGeneration;
using Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.DeliverAsDraftEmail;
using Inprotech.IntegrationServer.DocumentGeneration.Services.HtmlBodyConverter;
using Inprotech.Tests.Builders;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.DocumentGeneration.Delivery;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.DocumentGeneration.DeliverAsDraftEmail
{
    public class DraftEmailFacts : FactBase
    {
        readonly IDocItemRunner _docItemRunner = Substitute.For<IDocItemRunner>();
        readonly IEmailRecipientResolver _emailRecipientsResolver = Substitute.For<IEmailRecipientResolver>();
        readonly IHtmlBodyConverter _htmlBodyConverter = Substitute.For<IHtmlBodyConverter>();
        readonly EmailRecipients _recipients = new EmailRecipients();
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();

        DraftEmail CreateSubject()
        {
            _emailRecipientsResolver.Resolve(Arg.Any<int>())
                                    .Returns(_recipients);

            var htmlBodyConverterFactoryService = Substitute.For<IIndex<Category, IHtmlBodyConverter>>();
            htmlBodyConverterFactoryService.TryGetValue(Arg.Any<Category>(), out var value)
                                           .Returns(x =>
                                           {
                                               if ((Category) x[0] == Category.Unknown)
                                               {
                                                   x[1] = null;
                                                   return false;
                                               }

                                               x[1] = _htmlBodyConverter;
                                               return true;
                                           });

            return new DraftEmail(Db, _emailRecipientsResolver, _docItemRunner, htmlBodyConverterFactoryService, _fileSystem);
        }

        [Fact]
        public async Task ShouldCallComponentToResolveRecipients()
        {
            var queueId = Fixture.Integer();

            var letter = new Document
            {
                DocItemBody = Fixture.String()
            }.In(Db);

            _recipients.To.Add(Fixture.String());
            _recipients.Cc.Add(Fixture.String());
            _recipients.Bcc.Add(Fixture.String());

            var subject = CreateSubject();

            var r = await subject.Prepare(
                                          new DocGenRequest
                                          {
                                              Id = queueId,
                                              LetterId = letter.Id
                                          });

            Assert.Equal(_recipients.To.Single(), r.Recipients.Single());
            Assert.Equal(_recipients.Cc.Single(), r.CcRecipients.Single());
            Assert.Equal(_recipients.Bcc.Single(), r.BccRecipients.Single());

            _emailRecipientsResolver.Received(1).Resolve(queueId)
                                    .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldResolveEmailBodyByConvertingGeneratedDocumentAsHtmlUsingContentId()
        {
            var queueId = Fixture.Integer();
            var fileName = Path.Combine(@"c:\dms\", Fixture.String() + ".doc");
            var bodyExpected = Fixture.String();
            var attached = new EmailAttachment
            {
                Content = Fixture.String(),
                IsInline = true,
                ContentId = Fixture.String()
            };
            var letter = new Document().In(Db);

            _htmlBodyConverter.Convert(fileName)
                              .Returns((bodyExpected, new[] {attached}));

            var subject = CreateSubject();

            var r = await subject.Prepare(
                                          new DocGenRequest
                                          {
                                              Id = queueId,
                                              LetterId = letter.Id,
                                              FileName = fileName
                                          });

            Assert.Equal(bodyExpected, r.Body);
            Assert.True(r.IsBodyHtml);
            Assert.Equal(attached.IsInline, r.Attachments.Single().IsInline);
            Assert.Equal(attached.ContentId, r.Attachments.Single().ContentId);
            Assert.Equal(attached.Content, r.Attachments.Single().Content);
        }

        [Fact]
        public async Task ShouldResolveEmailBodyByConvertingGeneratedDocumentAsHtmlUsingDataStream()
        {
            var queueId = Fixture.Integer();
            var fileName = Path.Combine(@"c:\dms\", Fixture.String() + ".doc");
            var bodyExpected = Fixture.String();
            var letter = new Document().In(Db);

            _htmlBodyConverter.Convert(fileName)
                              .Returns((bodyExpected, Enumerable.Empty<EmailAttachment>()));

            var subject = CreateSubject();

            var r = await subject.Prepare(
                                          new DocGenRequest
                                          {
                                              Id = queueId,
                                              LetterId = letter.Id,
                                              FileName = fileName
                                          });

            Assert.Equal(bodyExpected, r.Body);
            Assert.True(r.IsBodyHtml);
            Assert.Empty(r.Attachments);
        }

        [Fact]
        public async Task ShouldResolveEmailBodyFromDataItemConfiguredInDeliverOnlyLetter()
        {
            var letter = new Document
            {
                DocItemBody = Fixture.String()
            }.In(Db);

            var queueId = Fixture.Integer();
            var fileName = Fixture.String();
            var bodyExpected = Fixture.String();

            _docItemRunner.Run(letter.DocItemBody, Arg.Any<Dictionary<string, object>>())
                          .Returns(new DataItemResultBuilder<string>(bodyExpected).Build());

            var subject = CreateSubject();

            var r = await subject.Prepare(
                                          new DocGenRequest
                                          {
                                              Id = queueId,
                                              LetterId = letter.Id,
                                              FileName = fileName
                                          });

            Assert.Equal(bodyExpected, r.Body);
            Assert.Equal(fileName, r.Attachments.Single().FileName);
            Assert.False(r.IsBodyHtml);
            _docItemRunner.Received(1)
                          .Run(letter.DocItemBody,
                               Arg.Is<Dictionary<string, object>>(x => (string) x["gstrEntryPoint"] == queueId.ToString()));
        }

        [Fact]
        public async Task ShouldResolveEmailSubjectFromConfiguredEmailStoredProcedureInDeliverOnlyLetter()
        {
            var letter = new Document().In(Db);

            var queueId = Fixture.Integer();
            
            _recipients.Subject = Fixture.String();

            var subject = CreateSubject();

            var r = await subject.Prepare(
                                          new DocGenRequest
                                          {
                                              Id = queueId,
                                              LetterId = letter.Id,
                                              FileName = Fixture.String()
                                          });

            Assert.Equal(_recipients.Subject, r.Subject);
        }

        [Fact]
        public async Task ShouldResolveEmailSubjectFromDataItemConfiguredInDeliverOnlyLetter()
        {
            var letter = new Document
            {
                DocItemSubject = Fixture.String()
            }.In(Db);

            var queueId = Fixture.Integer();
            var subjectExpected = Fixture.String();

            _docItemRunner.Run(letter.DocItemSubject, Arg.Any<Dictionary<string, object>>())
                          .Returns(new DataItemResultBuilder<string>(subjectExpected).Build());

            var subject = CreateSubject();

            var r = await subject.Prepare(
                                          new DocGenRequest
                                          {
                                              Id = queueId,
                                              LetterId = letter.Id,
                                              FileName = Fixture.String()
                                          });

            Assert.Equal(subjectExpected, r.Subject);

            _docItemRunner.Received(1)
                          .Run(letter.DocItemSubject,
                               Arg.Is<Dictionary<string, object>>(x => (string) x["gstrEntryPoint"] == queueId.ToString()));
        }

        [Fact]
        public async Task ShouldResolveEmailSubjectFromLetterNameAsFallback()
        {
            var queueId = Fixture.Integer();
            var subjectExpected = Fixture.String();

            var letter = new Document
            {
                DocItemBody = Fixture.String()
            }.In(Db);

            var subject = CreateSubject();

            var r = await subject.Prepare(
                                          new DocGenRequest
                                          {
                                              Id = queueId,
                                              LetterId = letter.Id,
                                              LetterName = subjectExpected
                                          });

            Assert.Equal(subjectExpected, r.Subject);
        }

        [Fact]
        public async Task ShouldResolveMailboxFromDataItemConfiguredInDeliverOnlyLetter()
        {
            var letter = new Document
            {
                DocItemMailbox = Fixture.String()
            }.In(Db);

            var queueId = Fixture.Integer();
            var mailboxExpected = Fixture.String();

            _docItemRunner.Run(letter.DocItemMailbox, Arg.Any<Dictionary<string, object>>())
                          .Returns(new DataItemResultBuilder<string>(mailboxExpected).Build());

            var subject = CreateSubject();

            var r = await subject.Prepare(
                                          new DocGenRequest
                                          {
                                              Id = queueId,
                                              LetterId = letter.Id,
                                              FileName = Fixture.String()
                                          });

            Assert.Equal(mailboxExpected, r.Mailbox);
            _docItemRunner.Received(1)
                          .Run(letter.DocItemMailbox,
                               Arg.Is<Dictionary<string, object>>(x => (string) x["gstrEntryPoint"] == queueId.ToString()));
        }

        [Fact]
        public async Task ShouldResolveEmailAttachmentsByConvertingGeneratedDocumentUsingDataStream()
        {
            var letter = new Document
            {
                DocItemBody = Fixture.String()
            }.In(Db);
            var queueId = Fixture.Integer();
            var fileName = Path.Combine(@"c:\dms\", Fixture.String() + ".doc");
            var bodyExpected = Fixture.String();
            var attached = new EmailAttachment
            {
                Content = Fixture.String(),
                IsInline = false,
                ContentId = Fixture.String()
            };
            _docItemRunner.Run(letter.DocItemBody, Arg.Any<Dictionary<string, object>>())
                          .Returns(new DataItemResultBuilder<string>(bodyExpected).Build());
            var file = Fixture.RandomBytes(1);
            _fileSystem.ReadAllBytes(fileName).Returns(file);
            var subject = CreateSubject();
            var r = await subject.Prepare(
                                          new DocGenRequest
                                          {
                                              Id = queueId,
                                              LetterId = letter.Id,
                                              FileName = fileName
                                          });

            Assert.Equal(bodyExpected, r.Body);
            Assert.False(r.IsBodyHtml);
            Assert.Equal(attached.IsInline, r.Attachments.Single().IsInline);
            Assert.Equal(Convert.ToBase64String(file), r.Attachments.Single().Content);
        }
    }
}