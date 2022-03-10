using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security
{
    public class UserFilteredTypesFacts
    {
        public class NameTypes : FactBase
        {
            [Fact]
            public void ReturnsAllNameTypesForInternalUsers()
            {
                var nameType1 = new NameTypeBuilder {Name = "ABC", NameTypeCode = "AAA"}.Build().In(Db);
                var nameType2 = new NameTypeBuilder {Name = "ASD", NameTypeCode = "BBB"}.Build().In(Db);
                var nameType3 = new NameTypeBuilder {Name = "XYZ", NameTypeCode = "CCC"}.Build().In(Db);
                var f = new UserFilteredTypesFixture(Db);
                f.SiteControls.Read<string>(SiteControls.ClientNameTypesShown).Returns(string.Join(",", nameType1.NameTypeCode, nameType2.NameTypeCode));

                var r = f.Subject.NameTypes().ToArray();
                Assert.Equal(3, r.Length);
                Assert.Equal(nameType1.Id, r[0].Id);
                Assert.Equal(nameType2.Id, r[1].Id);
                Assert.Equal(nameType3.Id, r[2].Id);
            }

            [Fact]
            public void ReturnsAllNameTypesWhenSiteControlEmpty()
            {
                var nameType1 = new NameTypeBuilder {Name = "ABC", NameTypeCode = "AAA"}.Build().In(Db);
                var nameType2 = new NameTypeBuilder {Name = "ASD", NameTypeCode = "BBB"}.Build().In(Db);
                var nameType3 = new NameTypeBuilder {Name = "XYZ", NameTypeCode = "CCC"}.Build().In(Db);
                var f = new UserFilteredTypesFixture(Db, true);
                f.SiteControls.Read<string>(SiteControls.ClientNameTypesShown).Returns(string.Empty);

                var r = f.Subject.NameTypes().ToArray();
                Assert.Equal(3, r.Length);
                Assert.Equal(nameType1.Id, r[0].Id);
                Assert.Equal(nameType2.Id, r[1].Id);
                Assert.Equal(nameType3.Id, r[2].Id);
            }

            [Fact]
            public void ReturnsFilteredNameTypesBasedOnSiteControl()
            {
                var nameType1 = new NameTypeBuilder {Name = "ABC", NameTypeCode = "AAA"}.Build().In(Db);
                var nameType2 = new NameTypeBuilder {Name = "XYZ", NameTypeCode = "ZZZ"}.Build().In(Db);
                new NameTypeBuilder().Build().In(Db);
                var f = new UserFilteredTypesFixture(Db, true);
                f.SiteControls.Read<string>(SiteControls.ClientNameTypesShown).Returns(string.Join(",", nameType1.NameTypeCode, nameType2.NameTypeCode));

                var r = f.Subject.NameTypes().ToArray();
                Assert.Equal(2, r.Length);
                Assert.Equal(nameType1.Id, r[0].Id);
                Assert.Equal(nameType2.Id, r[1].Id);
            }
        }

        public class NumberTypes : FactBase
        {
            [Fact]
            public void ReturnsAllNumberTypesForInternalUsers()
            {
                var numberType1 = new NumberTypeBuilder {Name = "ABC", Code = "AAA"}.Build().In(Db);
                var numberType2 = new NumberTypeBuilder {Name = "ASD", Code = "BBB"}.Build().In(Db);
                var numberType3 = new NumberTypeBuilder {Name = "XYZ", Code = "CCC"}.Build().In(Db);
                var f = new UserFilteredTypesFixture(Db);
                f.SiteControls.Read<string>(SiteControls.ClientNumberTypesShown).Returns(string.Join(",", numberType1.NumberTypeCode, numberType2.NumberTypeCode));

                var r = f.Subject.NumberTypes().ToArray();
                Assert.Equal(3, r.Length);
                Assert.Equal(numberType1.Id, r[0].Id);
                Assert.Equal(numberType2.Id, r[1].Id);
                Assert.Equal(numberType3.Id, r[2].Id);
            }

            [Fact]
            public void ReturnsFilteredNumberTypesBasedOnSiteControl()
            {
                var numberType1 = new NumberTypeBuilder {Name = "ABC", Code = "AAA"}.Build().In(Db);
                var numberType2 = new NumberTypeBuilder {Name = "XYZ", Code = "ZZZ"}.Build().In(Db);
                new NumberTypeBuilder().Build().In(Db);
                var f = new UserFilteredTypesFixture(Db, true);
                f.SiteControls.Read<string>(SiteControls.ClientNumberTypesShown).Returns(string.Join(",", numberType1.NumberTypeCode, numberType2.NumberTypeCode));

                var r = f.Subject.NumberTypes().ToArray();
                Assert.Equal(2, r.Length);
                Assert.Equal(numberType1.Id, r[0].Id);
                Assert.Equal(numberType2.Id, r[1].Id);
            }

            [Fact]
            public void ReturnsOnlyNumberTypesIssuedByIpOffice()
            {
                var numberType2 = new NumberTypeBuilder {Name = "ASD", Code = "BBB", IssuedByIpOffice = true}.Build().In(Db);
                new NumberTypeBuilder {Name = "ABC", Code = "AAA"}.Build().In(Db);
                new NumberTypeBuilder {Name = "XYZ", Code = "CCC"}.Build().In(Db);
                var f = new UserFilteredTypesFixture(Db, true);
                f.SiteControls.Read<string>(SiteControls.ClientNumberTypesShown).Returns(string.Empty);

                var r = f.Subject.NumberTypes().ToArray();
                Assert.Single(r);
                Assert.True(r.All(_ => _.Id == numberType2.Id && _.IssuedByIpOffice));
            }
        }

        public class TextTypes : FactBase
        {
            [Fact]
            public void ReturnsCaseTextTypesIfForCaseOnlyIsSetForInternalUsers()
            {
                var textType1 = new TextTypeBuilder {Description = "ABC", Id = "AA"}.Build().In(Db);
                var textType2 = new TextTypeBuilder {Description = "ASD", Id = "BB", UsedByFlag = 1}.Build().In(Db);
                var textType3 = new TextTypeBuilder {Description = "XYZ", Id = "CC"}.Build().In(Db);
                var f = new UserFilteredTypesFixture(Db);
                f.SiteControls.Read<bool>(SiteControls.AllowAllTextTypesForCases).Returns(false);
                f.SiteControls.Read<string>(SiteControls.ClientTextTypes).Returns(string.Join(",", textType1.Id, textType2.Id));

                var r = f.Subject.TextTypes(true).ToArray();
                Assert.Equal(2, r.Length);
                Assert.Equal(textType1.Id, r[0].Id);
                Assert.Equal(textType3.Id, r[1].Id);
            }

            [Fact]
            public void ReturnsAllTypesBasedOnSiteControls()
            {
                var textType1 = new TextTypeBuilder {Description = "ABC", Id = "AA", UsedByFlag = 1}.Build().In(Db);
                new TextTypeBuilder {Description = "ASD", Id = "BB", UsedByFlag = 1}.Build().In(Db);
                var textType3 = new TextTypeBuilder {Description = "XYZ", Id = "CC"}.Build().In(Db);
                var f = new UserFilteredTypesFixture(Db, true);
                f.SiteControls.Read<bool>(SiteControls.AllowAllTextTypesForCases).Returns(true);
                f.SiteControls.Read<string>(SiteControls.ClientTextTypes).Returns(string.Join(",", textType1.Id, textType3.Id));

                var r = f.Subject.TextTypes(true).ToArray();
                Assert.Equal(2, r.Length);
                Assert.Equal(textType1.Id, r[0].Id);
                Assert.Equal(textType3.Id, r[1].Id);
            }

            [Fact]
            public void ReturnsFilteredTextTypesBasedOnSiteControl()
            {
                var textType1 = new TextTypeBuilder {Description = "ABC", Id = "AB"}.Build().In(Db);
                var textType2 = new TextTypeBuilder {Description = "XYZ", Id = "XY"}.Build().In(Db);
                new TextTypeBuilder().Build().In(Db);
                var f = new UserFilteredTypesFixture(Db, true);
                f.SiteControls.Read<string>(SiteControls.ClientTextTypes).Returns(string.Join(",", textType1.Id, textType2.Id));

                var r = f.Subject.TextTypes().ToArray();
                Assert.Equal(2, r.Length);
                Assert.Equal(textType1.Id, r[0].Id);
                Assert.Equal(textType2.Id, r[1].Id);
            }

            [Fact]
            public void ReturnsUnflaggedTypesForCaseUse()
            {
                var textType1 = new TextTypeBuilder {Description = "ABC", Id = "AA", UsedByFlag = 1}.Build().In(Db);
                new TextTypeBuilder {Description = "ASD", Id = "BB", UsedByFlag = 1}.Build().In(Db);
                var textType3 = new TextTypeBuilder {Description = "XYZ", Id = "CC"}.Build().In(Db);
                var f = new UserFilteredTypesFixture(Db, true);
                f.SiteControls.Read<bool>(SiteControls.AllowAllTextTypesForCases).Returns(false);
                f.SiteControls.Read<string>(SiteControls.ClientTextTypes).Returns(string.Join(",", textType1.Id, textType3.Id));

                var r = f.Subject.TextTypes(true).ToArray();
                Assert.Single(r);
                Assert.Equal(textType3.Id, r[0].Id);
            }

            [Fact]
            public void ReturnsFilteredInstructionTypesBasedOnSiteControl()
            {
                var instType1 = new InstructionTypeBuilder {Description = "ABC", Code = "A"}.Build().In(Db);
                var instType2 = new InstructionTypeBuilder {Description = "XYZ", Code = "X"}.Build().In(Db);
                new InstructionTypeBuilder().Build().In(Db);
                var f = new UserFilteredTypesFixture(Db, true);
                f.SiteControls.Read<string>(SiteControls.ClientInstructionTypes).Returns(string.Join(",", instType1.Code, instType2.Code));

                var r = f.Subject.InstructionTypes().ToArray();
                Assert.Equal(2, r.Length);
                Assert.Equal(instType1.Code, r[0].Code);
                Assert.Equal(instType2.Code, r[1].Code);
            }
        }

        public class UserFilteredTypesFixture : IFixture<UserFilteredTypes>
        {
            public UserFilteredTypesFixture(InMemoryDbContext db, bool forExternal = false)
            {
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(new UserBuilder(db) {IsExternalUser = forExternal}.Build());
                SiteControls = Substitute.For<ISiteControlReader>();
                Subject = new UserFilteredTypes(db, SecurityContext, SiteControls);
            }

            public ISecurityContext SecurityContext { get; set; }
            public ISiteControlReader SiteControls { get; set; }
            public UserFilteredTypes Subject { get; set; }
        }
    }
}