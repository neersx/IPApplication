using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Tests.Web.Builders.BulkCaseImport;
using Inprotech.Web.BulkCaseImport.Validators;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport.Validators
{
    public class CpaXmlValidatorFacts
    {
        public class CpaXmlValidatorFixture : IFixture<ICpaXmlValidator>
        {
            public CpaXmlValidatorFixture()
            {
                SenderDetailsValidator = Substitute.For<ISenderDetailsValidator>();

                Subject = new CpaXmlValidator(SenderDetailsValidator);
            }

            public ISenderDetailsValidator SenderDetailsValidator { get; }
            public ICpaXmlValidator Subject { get; }
        }

        public class ValidateMethod
        {
            const string SenderFileName = "xmlFile.xml";
            const string ValidXml = "<cpaxml/>";
            const string InvalidXml = "IncorrectXML";

            [Fact]
            public void AcceptsValidXmlFileWithoutNamespace()
            {
                var f = new CpaXmlValidatorFixture();
                f.SenderDetailsValidator.Validate(Arg.Any<string>(), Arg.Any<XDocument>()).Returns(new List<ValidationError>());

                XNamespace ns;
                List<ValidationError> errors;
                var isValid = f.Subject.Validate(ValidXml, SenderFileName, out ns, out errors);

                Assert.True(isValid);
                Assert.Empty(errors);
                Assert.Same(XNamespace.None, ns);

                f.SenderDetailsValidator.Received(1).Validate(SenderFileName, Arg.Any<XDocument>());
            }

            [Fact]
            public void OnlyValidatesWithCpaxmlSchemaIfNamespaceIsValid()
            {
                var f = new CpaXmlValidatorFixture();
                f.SenderDetailsValidator.Validate(Arg.Any<string>(), Arg.Any<XDocument>()).Returns(new List<ValidationError>());

                var cpaxmldoc = new CpaXmlBuilder()
                                .WithInvalidNamespace()
                                .Build();

                XNamespace ns;
                List<ValidationError> errors;
                f.Subject.Validate(cpaxmldoc.ToString(), SenderFileName, out ns, out errors);

                Assert.Same(XNamespace.None, ns);
                Assert.NotSame(cpaxmldoc.Root.GetDefaultNamespace(), ns);

                f.SenderDetailsValidator.Received(1).Validate(SenderFileName, Arg.Any<XDocument>());
            }

            [Fact]
            public void RejectsInvalidXml()
            {
                var f = new CpaXmlValidatorFixture();

                XNamespace ns;
                List<ValidationError> errors;
                var isValid = f.Subject.Validate(InvalidXml, SenderFileName, out ns, out errors);

                Assert.False(isValid);
                Assert.NotEmpty(errors);
                Assert.Same(XNamespace.None, ns);

                f.SenderDetailsValidator.Received(0).Validate(SenderFileName, Arg.Any<XDocument>());
            }

            [Fact]
            public void ValidateUsingCpaxmlSchema()
            {
                var f = new CpaXmlValidatorFixture();
                f.SenderDetailsValidator.Validate(Arg.Any<string>(), Arg.Any<XDocument>()).Returns(new List<ValidationError>());

                var cpaxml = new CpaXmlBuilder().Build().ToString();

                XNamespace ns;
                List<ValidationError> errors;
                var isValid = f.Subject.Validate(cpaxml, SenderFileName, out ns, out errors);

                Assert.False(isValid);
                Assert.True(errors.Any());
                Assert.NotSame(XNamespace.None, ns);

                f.SenderDetailsValidator.Received(0).Validate(SenderFileName, Arg.Any<XDocument>());
            }
        }
    }
}