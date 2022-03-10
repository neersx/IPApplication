using Inprotech.Tests.Web;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.Security.Cryptography;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Security
{
    [Trait("Category", "Crypto")]
    public class IdentityBoundCryptoServiceFacts
    {
        readonly ISecurityContext _securityContext = Substitute.For<ISecurityContext>();

        [Fact]
        public void CipherTextDoesNotMatchPlainText()
        {
            var plainText = Fixture.String();

            _securityContext.User.Returns(new User(Fixture.String(), false));

            var subject = new IdentityBoundCryptoService(_securityContext);

            Assert.NotEqual(plainText, subject.Encrypt(plainText));
        }

        [Fact]
        public void ShouldDecryptEncryptedText()
        {
            var plainText = Fixture.String();

            _securityContext.User.Returns(new User(Fixture.String(), false));

            var subject = new IdentityBoundCryptoService(_securityContext);

            var cypherText = subject.Encrypt(plainText);

            Assert.Equal(plainText, subject.Decrypt(cypherText));
        }

        [Fact]
        public void ShouldDecryptEncryptedTextWithDomainName()
        {
            var plainText = Fixture.String();

            _securityContext.User.Returns(new User("int\\user", false));

            var subject = new IdentityBoundCryptoService(_securityContext);

            var cypherText = subject.Encrypt(plainText);

            Assert.Equal(plainText, subject.Decrypt(cypherText));
        }

        [Fact]
        public void ShouldEncryptBasedOnKeyDerivedFromIdentity()
        {
            var plainText = Fixture.String();

            var a1 = Create("internal", 34);
            var a2 = Create("internal", 34);
            var b1 = Create("demo", Fixture.Integer());

            var result1 = a1.Encrypt(plainText);
            var result2 = a2.Encrypt(plainText);
            var result3 = b1.Encrypt(plainText);

            Assert.Equal(result1, result2);

            Assert.NotEqual(result1, result3);

            IdentityBoundCryptoService Create(string userName, int id = 1)
            {
                var sc = Substitute.For<ISecurityContext>();
                sc.User.Returns(new User(userName, false).WithKnownId(id));

                return new IdentityBoundCryptoService(sc);
            }
        }
    }
}