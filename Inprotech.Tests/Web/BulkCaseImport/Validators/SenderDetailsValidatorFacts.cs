using System.Linq;
using System.Xml.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.BulkCaseImport;
using Inprotech.Web.BulkCaseImport.Validators;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport.Validators
{
    public class SenderDetailsValidatorFacts
    {
        public class SenderDetailsValidatorFixture : IFixture<SenderDetailsValidator>
        {
            readonly InMemoryDbContext _db;

            public SenderDetailsValidatorFixture(InMemoryDbContext db)
            {
                _db = db;
                db.Set<EdeRequestType>().Add(new EdeRequestType {RequestTypeCode = "Case Import"}).In(db);
                db.Set<EdeRequestType>().Add(new EdeRequestType {RequestTypeCode = "Agent Input"}).In(db);

                Subject = new SenderDetailsValidator(db);
            }

            public SenderDetails SenderDetailsFixture => new SenderDetails
            {
                RequestType = KnownSenderRequestTypes.CaseImport,
                RequestIdentifier = "12136513",
                Sender = "MYAC",
                SenderFileName = "abc.xml"
            };

            public SenderDetailsValidator Subject { get; }

            public SenderDetailsValidatorFixture WithValidNameAlias(string alias, string name)
            {
                new NameAlias
                {
                    Alias = alias,
                    Name = new Name {LastName = name}.In(_db),
                    AliasType = new NameAliasType {Code = KnownAliasTypes.EdeIdentifier}
                }.In(_db);

                return this;
            }

            public SenderDetailsValidatorFixture WithExistingSenderRequest(string sender, string identifier)
            {
                new EdeSenderDetails
                {
                    SenderRequestIdentifier = identifier,
                    Sender = sender
                }.In(_db);

                return this;
            }
        }

        public class ValidateMethod : FactBase
        {
            [Fact]
            public void PassesValidationForAllowedRequestTypes()
            {
                var f = new SenderDetailsValidatorFixture(Db)
                    .WithValidNameAlias("MYAC", "Maxim Yarrow and Colman");

                f.SenderDetailsFixture.RequestType = KnownSenderRequestTypes.AgentInput;

                var cpaxml = new CpaXmlBuilder()
                             .WithoutNamespace()
                             .WithSenderDetails(f.SenderDetailsFixture).Build();

                var errors = f.Subject.Validate("abc.xml", cpaxml);

                Assert.False(errors.Any());
            }

            [Fact]
            public void PassesValidationForXmlWithNamespace()
            {
                var f = new SenderDetailsValidatorFixture(Db)
                    .WithValidNameAlias("MYAC", "Maxim Yarrow and Colman");

                var cpaxml = new CpaXmlBuilder().WithSenderDetails(f.SenderDetailsFixture).Build();

                var errors = f.Subject.Validate("abc.xml", cpaxml);

                Assert.False(errors.Any());
            }

            [Fact]
            public void PassesValidationIfNoErrors()
            {
                var f = new SenderDetailsValidatorFixture(Db)
                    .WithValidNameAlias("MYAC", "Maxim Yarrow and Colman");

                var cpaxml = new CpaXmlBuilder()
                             .WithoutNamespace()
                             .WithSenderDetails(f.SenderDetailsFixture).Build();

                var errors = f.Subject.Validate("abc.xml", cpaxml);

                Assert.False(errors.Any());
            }

            [Fact]
            public void ReturnsErrorWhenInputFileNameDoesNotMatchSenderFileNameInCpaXml()
            {
                var f = new SenderDetailsValidatorFixture(Db)
                    .WithValidNameAlias("MYAC", "Maxim Yarrow and Colman");

                var cpaxml = new CpaXmlBuilder()
                             .WithoutNamespace()
                             .WithSenderDetails(f.SenderDetailsFixture).Build();

                var errors = f.Subject.Validate("WrongFileName.xml", cpaxml);

                Assert.Equal(Resources.ErrorFileNameMustMatchSenderFilename, errors.Single().ErrorMessage);
            }

            [Fact]
            public void ReturnsErrorWhenSenderDetailsNotFoundOrTooMany()
            {
                var f = new SenderDetailsValidatorFixture(Db);

                var errors = f.Subject.Validate("invalid.xml", XDocument.Parse("<invalidcpaxml />"));

                Assert.Equal(Resources.ErrorTooManySenderDetailsOrNotFound, errors.Single().ErrorMessage);
            }

            [Fact]
            public void ReturnsErrorWhenSenderFilenameNotFound()
            {
                var f = new SenderDetailsValidatorFixture(Db)
                    .WithValidNameAlias("MYAC", "Maxim Yarrow and Colman");

                var senderDetails = f.SenderDetailsFixture;
                senderDetails.SenderFileName = string.Empty;

                var cpaxml = new CpaXmlBuilder()
                             .WithoutNamespace()
                             .WithSenderDetails(senderDetails).Build();

                var errors = f.Subject.Validate("anyfilename.xml", cpaxml);

                Assert.Equal(Resources.ErrorSenderFilenameMustExist,
                             errors.Single().ErrorMessage);
            }

            [Fact]
            public void ReturnsErrorWhenSenderIdentifierIsBlank()
            {
                var f = new SenderDetailsValidatorFixture(Db)
                        .WithValidNameAlias("MYAC", "Maxim Yarrow and Colman")
                        .WithExistingSenderRequest("MYAC", "existing request id");

                var senderDetails = f.SenderDetailsFixture;
                senderDetails.RequestIdentifier = string.Empty;

                var cpaxml = new CpaXmlBuilder()
                             .WithoutNamespace()
                             .WithSenderDetails(senderDetails).Build();

                var errors = f.Subject.Validate("abc.xml", cpaxml);

                Assert.Equal(Resources.ErrorSenderIdentifierMustExist, errors.Single().ErrorMessage);
            }

            [Fact]
            public void ReturnsErrorWhenSenderIsMappedMoreThanOnce()
            {
                var f = new SenderDetailsValidatorFixture(Db)
                        .WithValidNameAlias("MS", "Microsoft")
                        .WithValidNameAlias("MS", "MySpace.com");

                var senderDetails = f.SenderDetailsFixture;
                senderDetails.Sender = "MS";

                var cpaxml = new CpaXmlBuilder()
                             .WithoutNamespace()
                             .WithSenderDetails(senderDetails).Build();

                var errors = f.Subject.Validate(senderDetails.SenderFileName, cpaxml);

                var message = string.Format(Resources.ErrorSenderMappedToMoreThanOneNameAliases, "MS");

                Assert.Equal(message, errors.Single().ErrorMessage);
            }

            [Fact]
            public void ReturnsErrorWhenSenderIsUnknown()
            {
                var f = new SenderDetailsValidatorFixture(Db);

                var senderDetails = f.SenderDetailsFixture;
                senderDetails.Sender = "NotMappedToAnyName";

                var cpaxml = new CpaXmlBuilder()
                             .WithoutNamespace()
                             .WithSenderDetails(senderDetails).Build();

                var errors = f.Subject.Validate(senderDetails.SenderFileName, cpaxml);

                var message = string.Format(Resources.ErrorSenderNotMappedOrNotProvided, "NotMappedToAnyName");

                Assert.Equal(message, errors.Single().ErrorMessage);
            }

            [Fact]
            public void ReturnsErrorWhenSenderRequestIsNotUnique()
            {
                var f = new SenderDetailsValidatorFixture(Db)
                        .WithValidNameAlias("MYAC", "Maxim Yarrow and Colman")
                        .WithExistingSenderRequest("MYAC", "existing request id");

                var senderDetails = f.SenderDetailsFixture;
                senderDetails.RequestIdentifier = "existing request id";

                var cpaxml = new CpaXmlBuilder()
                             .WithoutNamespace()
                             .WithSenderDetails(senderDetails).Build();

                var errors = f.Subject.Validate("abc.xml", cpaxml);

                var name = Db.Set<Name>().Single().Formatted();

                var expected = string.Format(Resources.ErrorDuplicateSenderRequest, name, "existing request id");

                Assert.Equal(expected, errors.Single().ErrorMessage);
            }

            [Fact]
            public void ReturnsErrorWhenUnknownRequestTypeIsProvided()
            {
                var f = new SenderDetailsValidatorFixture(Db)
                    .WithValidNameAlias("MYAC", "Maxim Yarrow and Colman");

                var senderDetails = f.SenderDetailsFixture;
                senderDetails.RequestType = "Some random request type";

                var cpaxml = new CpaXmlBuilder()
                             .WithoutNamespace()
                             .WithSenderDetails(senderDetails).Build();

                var errors = f.Subject.Validate("abc.xml", cpaxml);

                var expected = string.Format(Resources.ErrorUnknownSenderRequestType, "Some random request type");

                Assert.Equal(expected, errors.Single().ErrorMessage);
            }
        }

        public class IsValidRequestTypeMethod : FactBase
        {
            [Fact]
            void ReturnsInValidForInvalidRequestTypes()
            {
                var f = new SenderDetailsValidatorFixture(Db);
                Assert.False(f.Subject.IsValidRequestType("Agent Response"));

                Assert.False(f.Subject.IsValidRequestType("DATA INPUT"));
            }

            [Fact]
            void ReturnsValidForValidRequestTypes()
            {
                var f = new SenderDetailsValidatorFixture(Db);
                Assert.True(f.Subject.IsValidRequestType("Case Import"));

                Assert.True(f.Subject.IsValidRequestType("CASE import"));

                Assert.True(f.Subject.IsValidRequestType("Agent input"));
            }
        }
    }
}