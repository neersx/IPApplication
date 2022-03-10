using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases
{
    public class CaseViewNamesProviderFacts : FactBase
    {
        public class GetNamesMethodForNonDebtorTypes : FactBase
        {
            [Theory]
            [InlineData("A", null, "A")]
            [InlineData("A", "B", "A, B")]
            [InlineData(null, null, "")]
            public async Task ShouldFormatNameVariantsAccordingly(string last, string first, string expected)
            {
                var @case = new CaseBuilder().Build().In(Db);
                var nv = new NameVariantBuilder(Db).Build().In(Db);
                nv.FirstNameVariant = first;
                nv.NameVariantDesc = last;
                var fixture = new CaseViewNamesProviderFixture(Db)
                              .WithNameType("A", out var nt)
                              .WithCaseName(@case, nt, nv: nv);

                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).ToArray();

                Assert.Equal(expected, r.Single().NameVariant);
            }

            [Theory]
            [InlineData(1, true)]
            [InlineData(0, false)]
            [InlineData(null, false)]
            public async Task ShouldIndicateNameInherited(int? isInheritedFlag, bool expected)
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                var fixture = new CaseViewNamesProviderFixture(Db)
                              .WithNameType("O", out var nt).WithCaseName(@case, nt, name);

                @case.CaseNames.Single().IsInherited = isInheritedFlag;

                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).ToArray();

                Assert.Equal(expected, r.Single().IsInherited);
            }

            [Theory]
            [InlineData(1, true)]
            [InlineData(0, false)]
            public async Task ShouldIndicateAttentionNameDerivedFromFlagAndName(int isDerivedFlag, bool expected)
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                var attn = new NameBuilder(Db).Build().In(Db);
                var fixture = new CaseViewNamesProviderFixture(Db)
                              .WithNameType("O", out var nt).WithCaseName(@case, nt, name, attn: attn);

                @case.CaseNames.Single().IsDerivedAttentionName = isDerivedFlag;

                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).ToArray();

                Assert.Equal(expected, r.Single().IsAttentionDerived);
            }

            [Theory]
            [InlineData(ApplicationTask.EmailOurCaseContact, true)]
            [InlineData(ApplicationTask.EmailCaseResponsibleStaff, false)]
            public async Task ShouldReturnTelecomFromAttentionName(ApplicationTask task, bool userIsExternal)
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                var attn = new NameBuilder(Db)
                {
                    Email = new TelecommunicationBuilder {TelecomNumber = "someone@somewhere.com"}.Build().In(Db),
                    Phone = new TelecommunicationBuilder {TelecomNumber = "374242234"}.Build().In(Db)
                }.Build().In(Db);
                var fixture = new CaseViewNamesProviderFixture(Db, userIsExternal)
                              .WithNameType("O", out var nt).WithCaseName(@case, nt, name, attn: attn);

                fixture.TaskSecurityProvider.HasAccessTo(task).Returns(true);
                fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name.Id, attn.Id});
                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).Single();

                Assert.Equal(attn.MainEmailAddress(), r.Email);
                Assert.Equal(attn.MainPhone().Formatted(), r.Phone);
            }

            [Theory]
            [InlineData(ApplicationTask.EmailOurCaseContact, true)]
            [InlineData(ApplicationTask.EmailCaseResponsibleStaff, false)]
            public async Task ShouldReturnTelecomFromMainName(ApplicationTask task, bool userIsExternal)
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name = new NameBuilder(Db)
                {
                    Email = new TelecommunicationBuilder {TelecomNumber = "someone@somewhere.com"}.Build().In(Db),
                    Phone = new TelecommunicationBuilder {TelecomNumber = "374242234"}.Build().In(Db)
                }.Build().In(Db);
                var attn = new NameBuilder(Db).Build().In(Db);
                var fixture = new CaseViewNamesProviderFixture(Db, userIsExternal)
                              .WithNameType("O", out var nt).WithCaseName(@case, nt, name, attn: attn);

                fixture.TaskSecurityProvider.HasAccessTo(task).Returns(true);
                fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name.Id, attn.Id});
                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).Single();

                Assert.Equal(name.MainEmailAddress(), r.Email);
                Assert.Equal(name.MainPhone().Formatted(), r.Phone);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ShouldNotReturnTelecom(bool userIsExternal)
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name = new NameBuilder(Db)
                {
                    Email = new TelecommunicationBuilder {TelecomNumber = "mainname@somewhere.com"}.Build().In(Db),
                    Phone = new TelecommunicationBuilder {TelecomNumber = "374242234"}.Build().In(Db)
                }.Build().In(Db);
                var attn = new NameBuilder(Db)
                {
                    Email = new TelecommunicationBuilder {TelecomNumber = "attention@somewhere.com"}.Build().In(Db),
                    Phone = new TelecommunicationBuilder {TelecomNumber = "374242234"}.Build().In(Db)
                }.Build().In(Db);
                var fixture = new CaseViewNamesProviderFixture(Db, userIsExternal)
                              .WithNameType("O", out var nt).WithCaseName(@case, nt, name, attn: attn);

                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).Single();

                Assert.Null(r.Email);
                Assert.Null(r.Phone);
            }

            [Theory]
            [InlineData(true, "Slow paying customer", null)]
            [InlineData(false, "Slow paying customer", "Slow paying customer")]
            public async Task ShouldReturnRemarksAccordingly(bool isExternalUser, string availableComments, string expectedComments)
            {
                var fixture = new CaseViewNamesProviderFixture(Db, isExternalUser);
                var f = CreateCaseNamesAB(fixture);

                f.ntA.ColumnFlag |= KnownNameTypeColumnFlags.DisplayRemarks;
                f.ntB.ColumnFlag &= ~KnownNameTypeColumnFlags.DisplayRemarks;

                f.cn1.Remarks = availableComments;
                f.cn2.Remarks = Fixture.String();

                var r = (await fixture.Subject
                                      .GetNames(f.id, new string[0], Fixture.Integer())).ToArray();

                var r1 = r.Single(_ => _.TypeId == f.ntA.NameTypeCode);
                var r2 = r.Single(_ => _.TypeId == f.ntB.NameTypeCode);

                Assert.Equal(expectedComments, r1.Comments);
                Assert.Null(r2.Comments);
            }

            (int id, NameType ntA, NameType ntB, CaseName cn1, CaseName cn2) CreateCaseNamesAB(CaseViewNamesProviderFixture fixture)
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name1 = new NameBuilder(Db).Build().In(Db);
                var name2 = new NameBuilder(Db).Build().In(Db);
                fixture.WithNameType("A", out var nt1).WithCaseName(@case, nt1, name1);
                fixture.WithNameType("B", out var nt2).WithCaseName(@case, nt2, name2);
                nt1.ColumnFlag = KnownNameTypeColumnFlags.DisplayInherited;
                nt2.ColumnFlag = KnownNameTypeColumnFlags.DisplayInherited;
                var cn1 = @case.CaseNames.Single(_ => _.NameTypeId == "A");
                var cn2 = @case.CaseNames.Single(_ => _.NameTypeId == "B");
                fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name1.Id, name2.Id});
                return (@case.Id, nt1, nt2, cn1, cn2);
            }

            [Fact]
            public async Task ShouldFormatNameAndNameCodeAccordingly()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name1 = new NameBuilder(Db) {NameCode = Fixture.String()}.Build().In(Db);
                var name2 = new NameBuilder(Db) {NameCode = string.Empty}.Build().In(Db);

                var fixture = new CaseViewNamesProviderFixture(Db)
                              .WithNameType("A", out var nt1).WithCaseName(@case, nt1, name1)
                              .WithNameType("B", out var nt2).WithCaseName(@case, nt2, name1)
                              .WithNameType("C", out var nt3).WithCaseName(@case, nt3, name2);

                nt1.ShowNameCode = 1m;
                nt2.ShowNameCode = 2m;
                nt3.ShowNameCode = null;

                fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name1.Id, name2.Id});

                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).ToArray();

                var name1Formatted = name1.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName);
                var name2Formatted = name2.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName);

                Assert.Equal(name1Formatted, r.Single(_ => _.TypeId == nt1.NameTypeCode).Name);
                Assert.Equal($"{{{name1.NameCode}}} {name1.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName)}", r.Single(_ => _.TypeId == nt1.NameTypeCode).NameAndCode);

                Assert.Equal(name1Formatted, r.Single(_ => _.TypeId == nt2.NameTypeCode).Name);
                Assert.Equal($"{name1.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName)} {{{name1.NameCode}}}", r.Single(_ => _.TypeId == nt2.NameTypeCode).NameAndCode);

                Assert.Equal(name2Formatted, r.Single(_ => _.TypeId == nt3.NameTypeCode).Name);
                Assert.Equal(name2Formatted, r.Single(_ => _.TypeId == nt3.NameTypeCode).NameAndCode);
            }

            [Fact]
            public async Task ShouldIgnoreRestrictionsForExternalUser()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name1 = new NameBuilder(Db)
                {
                    NameCode = Fixture.String(),
                    Email = new TelecommunicationBuilder {TelecomNumber = "mainName@somewhere.com"}.Build().In(Db),
                    Phone = new TelecommunicationBuilder {TelecomNumber = "333333333"}.Build().In(Db)
                }.Build().In(Db);

                var attnName = new NameBuilder(Db)
                {
                    NameCode = string.Empty,
                    Email = new TelecommunicationBuilder {TelecomNumber = "attnName@somewhere.com"}.Build().In(Db),
                    Phone = new TelecommunicationBuilder {TelecomNumber = "4444444"}.Build().In(Db)
                }.Build().In(Db);

                var fixture = new CaseViewNamesProviderFixture(Db, true)
                              .WithNameType("A", out var nt1).WithCaseName(@case, nt1, name1, attn: attnName)
                              .WithNameType("B", out var nt2).WithCaseName(@case, nt2, attnName);

                nt1.ColumnFlag = KnownNameTypeColumnFlags.DisplayTelecom;
                nt2.ColumnFlag = KnownNameTypeColumnFlags.DisplayTelecom;

                fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name1.Id});

                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).ToArray();

                Assert.Equal(2, r.Length);
                Assert.True(r[0].CanView);
                Assert.Equal(attnName.MainEmailAddress(), r[0].Email);
                Assert.Equal(attnName.MainPhone().TelecomNumber, r[0].Phone);

                Assert.True(r[1].CanView);
                Assert.Equal(attnName.MainEmailAddress(), r[1].Email);
                Assert.Equal(attnName.MainPhone().TelecomNumber, r[1].Phone);
            }

            [Fact]
            public async Task ShouldNotIndicateAttentionNameDerivedWhenAttentionNotProvided()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                var fixture = new CaseViewNamesProviderFixture(Db)
                              .WithNameType("O", out var nt).WithCaseName(@case, nt, name);

                @case.CaseNames.Single().IsDerivedAttentionName = 1;

                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).ToArray();

                Assert.False(r.Single().IsAttentionDerived);
            }

            [Fact]
            public async Task ShouldReturnAccessibleFlags()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name1 = new NameBuilder(Db)
                {
                    NameCode = Fixture.String(),
                    Email = new TelecommunicationBuilder {TelecomNumber = "mainName@somewhere.com"}.Build().In(Db),
                    Phone = new TelecommunicationBuilder {TelecomNumber = "333333333"}.Build().In(Db)
                }.Build().In(Db);

                var attnName = new NameBuilder(Db)
                {
                    NameCode = string.Empty,
                    Email = new TelecommunicationBuilder {TelecomNumber = "attnName@somewhere.com"}.Build().In(Db),
                    Phone = new TelecommunicationBuilder {TelecomNumber = "4444444"}.Build().In(Db)
                }.Build().In(Db);

                var fixture = new CaseViewNamesProviderFixture(Db)
                              .WithNameType("A", out var nt1).WithCaseName(@case, nt1, name1, attn: attnName)
                              .WithNameType("B", out var nt2).WithCaseName(@case, nt2, name1)
                              .WithNameType("C", out var nt3).WithCaseName(@case, nt3, attnName);

                nt1.ColumnFlag = KnownNameTypeColumnFlags.DisplayTelecom;
                nt2.ColumnFlag = KnownNameTypeColumnFlags.DisplayTelecom;
                nt3.ColumnFlag = KnownNameTypeColumnFlags.DisplayTelecom;

                fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name1.Id});

                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).ToArray();

                Assert.Equal(3, r.Length);
                Assert.True(r[0].CanView);
                Assert.Equal(attnName.MainEmailAddress(), r[0].Email);
                Assert.Equal(attnName.MainPhone().TelecomNumber, r[0].Phone);

                Assert.True(r[1].CanView);
                Assert.Equal(name1.MainEmailAddress(), r[1].Email);
                Assert.Equal(name1.MainPhone().TelecomNumber, r[1].Phone);

                Assert.False(r[2].CanView);
                Assert.Null(r[2].Email);
                Assert.Null(r[2].Phone);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ShouldReturnWebsite(bool userIsExternal)
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name = new NameBuilder(Db).Build().In(Db);

                var websiteTableCode = new TableCode() {Id = (int) KnownTelecomTypes.Website}.In(Db);
                var webAddress = new TelecommunicationBuilder { TelecomNumber = "www.aaa.com", TelecomType = websiteTableCode}.Build().In(Db);
                name.Telecoms.Add(new NameTelecomBuilder(Db) {Name = name, Telecommunication = webAddress}.Build().In(Db));
                
                var fixture = new CaseViewNamesProviderFixture(Db, userIsExternal)
                              .WithNameType("O", out var nt).WithCaseName(@case, nt, name);

                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).Single();

                Assert.NotNull(r.Website);
            }
            [Fact]
            public async Task ShouldReturnAddressFromMainName()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                var addr = new NameAddressBuilder(Db).ForName(name).As(AddressType.Postal).Build().In(Db);
                name.PostalAddressId = addr.AddressId;
                var fixture = new CaseViewNamesProviderFixture(Db)
                              .WithNameType("O", out var nt).WithCaseName(@case, nt, name);

                nt.ColumnFlag = KnownNameTypeColumnFlags.DisplayAddress;
                fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name.Id});

                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).ToArray();

                Assert.True(r.Single().IsAddressInherited);
                Assert.Equal(addr.Address.Formatted(), r.Single().Address);
            }

            [Fact]
            public async Task ShouldReturnAssignmentDateAccordingly()
            {
                var fixture = new CaseViewNamesProviderFixture(Db);
                var f = CreateCaseNamesAB(fixture);

                f.ntA.ColumnFlag |= KnownNameTypeColumnFlags.DisplayAssignDate;
                f.ntB.ColumnFlag &= ~KnownNameTypeColumnFlags.DisplayAssignDate;

                f.cn1.AssignmentDate = Fixture.Today();
                f.cn2.AssignmentDate = Fixture.PastDate();

                var r = (await fixture.Subject
                                      .GetNames(f.id, new string[0], Fixture.Integer())).ToArray();

                var r1 = r.Single(_ => _.TypeId == f.ntA.NameTypeCode);
                var r2 = r.Single(_ => _.TypeId == f.ntB.NameTypeCode);

                Assert.Equal(f.cn1.AssignmentDate, r1.AssignDate);
                Assert.Null(r2.AssignDate);
            }

            [Fact]
            public async Task ShouldReturnBillPercentageAccordingly()
            {
                var fixture = new CaseViewNamesProviderFixture(Db);
                var f = CreateCaseNamesAB(fixture);

                f.ntA.ColumnFlag |= KnownNameTypeColumnFlags.DisplayBillPercentage;
                f.ntB.ColumnFlag &= ~KnownNameTypeColumnFlags.DisplayBillPercentage;

                f.cn1.BillingPercentage = 50;
                f.cn2.BillingPercentage = 89.9m;

                var r = (await fixture.Subject
                                      .GetNames(f.id, new string[0], Fixture.Integer())).ToArray();

                var r1 = r.Single(_ => _.TypeId == f.ntA.NameTypeCode);
                var r2 = r.Single(_ => _.TypeId == f.ntB.NameTypeCode);

                Assert.Equal((int?) f.cn1.BillingPercentage, r1.BillingPercentage);
                Assert.Null(r2.BillingPercentage);
            }

            [Fact]
            public async Task ShouldReturnCeasedDateAccordingly()
            {
                var fixture = new CaseViewNamesProviderFixture(Db);
                var f = CreateCaseNamesAB(fixture);

                f.ntA.ColumnFlag |= KnownNameTypeColumnFlags.DisplayDateCeased;
                f.ntB.ColumnFlag &= ~KnownNameTypeColumnFlags.DisplayDateCeased;

                f.cn1.ExpiryDate = Fixture.Today();
                f.cn2.ExpiryDate = Fixture.FutureDate();

                var r = (await fixture.Subject
                                      .GetNames(f.id, new string[0], Fixture.Integer())).ToArray();

                var r1 = r.Single(_ => _.TypeId == f.ntA.NameTypeCode);
                var r2 = r.Single(_ => _.TypeId == f.ntB.NameTypeCode);

                Assert.Equal(f.cn1.ExpiryDate, r1.ExpiryDate);
                Assert.Null(r2.ExpiryDate);
            }

            [Fact]
            public async Task ShouldReturnCorrespondenceDetailsFromCaseName()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var attn = new NameBuilder(Db).Build().In(Db);
                var addr = new AddressBuilder().Build().In(Db);
                var name = new NameBuilder(Db).Build().In(Db);

                var fixture = new CaseViewNamesProviderFixture(Db)
                              .WithNameType("O", out var nt)
                              .WithCaseName(@case, nt, name, attn: attn, addr: addr);

                fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {attn.Id, name.Id});

                nt.ColumnFlag = KnownNameTypeColumnFlags.DisplayAddress;

                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).ToArray();

                Assert.False(r.Single().IsAddressInherited);
                Assert.Equal($"{attn.FirstName} {attn.LastName}", r.Single().Attention);
                Assert.Equal(addr.Formatted(), r.Single().Address);
            }

            [Fact]
            public async Task ShouldReturnDateCommencedAccordingly()
            {
                var fixture = new CaseViewNamesProviderFixture(Db);
                var f = CreateCaseNamesAB(fixture);

                f.ntA.ColumnFlag |= KnownNameTypeColumnFlags.DisplayDateCommenced;
                f.ntB.ColumnFlag &= ~KnownNameTypeColumnFlags.DisplayDateCommenced;

                f.cn1.StartingDate = Fixture.FutureDate();
                f.cn2.StartingDate = Fixture.PastDate();

                var r = (await fixture.Subject
                                      .GetNames(f.id, new string[0], Fixture.Integer())).ToArray();

                var r1 = r.Single(_ => _.TypeId == f.ntA.NameTypeCode);
                var r2 = r.Single(_ => _.TypeId == f.ntB.NameTypeCode);

                Assert.Equal(f.cn1.StartingDate, r1.CommenceDate);
                Assert.Null(r2.CommenceDate);
            }

            [Fact]
            public async Task ShouldReturnNamesBelongingToAllowableNameTypes()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var fixture = new CaseViewNamesProviderFixture(Db)
                              .WithNameType("Z", out var ntAllowed1).WithCaseName(@case, ntAllowed1)
                              .WithNameType("Y", out var ntAllowed2).WithCaseName(@case, ntAllowed2)
                              .WithNameType("X", out var ntAllowed3).WithCaseName(@case, ntAllowed3)
                              .WithNameType("W", out var ntAllowed4, false).WithCaseName(@case, ntAllowed4);

                var r = (await fixture.Subject
                                      .GetNames(@case.Id, new string[0], Fixture.Integer())).ToArray();

                Assert.Equal(3, r.Length);
                Assert.Equal(new[] {"Z", "Y", "X"}, r.Select(_ => _.TypeId));
            }
        }

        public class GetNamesMethodForDebtorsAndRenewalDebtors : FactBase
        {
            /*
            -- For Debtor and Renewal Debtor (name types 'D' and 'Z') Attention and Address should be 
            -- extracted in the same manner as billing (SQA7355):
            -- 1)   Details recorded on the CaseName table; if no information is found then step 2 will be performed;
            -- 2)   If the debtor was inherited from the associated name then the details recorded against this 
            --      associated name will be returned; if the debtor was not inherited then go to the step 3;
            -- 3)   Check if the Address/Attention has been overridden on the AssociatedName table with 
                --  Relationship = 'BIL' and NameNo = RelatedName; if no information was found then go to the step 4; 
            -- 4)   Extract the Attention and Address details stored against the Name as the PostalAddress 
            --  and MainContact.
            */

            public class AttentionNameScenario : FactBase
            {
                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldStep1ReturnAttentionNameFromCaseName(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);

                    var n = new NameBuilder(Db).Build().In(Db);
                    var att = new NameBuilder(Db).Build().In(Db);
                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = n,
                        NameType = nt,
                        AttentionName = att
                    }.Build().In(Db);
                    fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {n.Id, att.Id});

                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.Equal($"{att.FirstName} {att.LastName}", r.Single().Attention);
                }

                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldStep2ReturnAttentionFromInheritedAssociatedNameRelationship(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);

                    var seq = Fixture.Short();
                    var relationship = Fixture.String();
                    var inheritedName = new NameBuilder(Db).Build().In(Db);
                    var name = new NameBuilder(Db).Build().In(Db);
                    var attention = new NameBuilder(Db).Build().In(Db);
                    new AssociatedNameBuilder(Db)
                    {
                        Name = inheritedName,
                        RelatedName = name,
                        Relationship = relationship,
                        Sequence = seq,
                        ContactName = attention
                    }.Build().In(Db);
                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = name,
                        NameType = nt
                    }.Build().In(Db);

                    cn.InheritedFromNameId = inheritedName.Id;
                    cn.InheritedFromRelationId = relationship;
                    cn.InheritedFromSequence = seq;
                    fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {inheritedName.Id, name.Id, attention.Id});

                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.Equal($"{attention.FirstName} {attention.LastName}", r.Single().Attention);
                }

                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldStep3ReturnAttentionDerivedFromUninheritedSendBillsToRelationship(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);
                    var name = new NameBuilder(Db).Build().In(Db);
                    var attention = new NameBuilder(Db).Build().In(Db);
                    new AssociatedNameBuilder(Db)
                    {
                        Name = name,
                        RelatedName = name,
                        Relationship = KnownRelations.SendBillsTo,
                        ContactName = attention
                    }.Build().In(Db);
                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = name,
                        NameType = nt
                    }.Build().In(Db);
                    fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name.Id, attention.Id});
                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.Equal($"{attention.FirstName} {attention.LastName}", r.Single().Attention);
                }

                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldStep4ReturnAttentionFromMainContact(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);

                    var attention = new NameBuilder(Db).Build().In(Db);
                    var name = new NameBuilder(Db)
                    {
                        MainContact = attention
                    }.Build().In(Db);

                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = name,
                        NameType = nt
                    }.Build().In(Db);

                    fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name.Id, attention.Id});
                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.Equal($"{attention.FirstName} {attention.LastName}", r.Single().Attention);
                }

                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldPickAttentionFromNameTypeInheritanceOverMainNameContact(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);

                    var seq = Fixture.Short();
                    var relationship = Fixture.String();
                    var inheritedName = new NameBuilder(Db).Build().In(Db);
                    var name = new NameBuilder(Db).Build().In(Db);
                    var attention = new NameBuilder(Db).Build().In(Db);
                    var attentionDecoy2 = new NameBuilder(Db).Build().In(Db);

                    name.MainContact = attentionDecoy2;

                    new AssociatedNameBuilder(Db)
                    {
                        Name = inheritedName,
                        RelatedName = name,
                        Relationship = relationship,
                        Sequence = seq,
                        ContactName = attention
                    }.Build().In(Db);
                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = name,
                        NameType = nt
                    }.Build().In(Db);

                    cn.InheritedFromNameId = inheritedName.Id;
                    cn.InheritedFromRelationId = relationship;
                    cn.InheritedFromSequence = seq;

                    fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name.Id, attention.Id, attentionDecoy2.Id});
                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.Equal($"{attention.FirstName} {attention.LastName}", r.Single().Attention);
                }

                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldPickAttentionFromNameTypeInheritanceOverSendBillsToRelationship(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);

                    var seq = Fixture.Short();
                    var relationship = Fixture.String();
                    var inheritedName = new NameBuilder(Db).Build().In(Db);
                    var name = new NameBuilder(Db).Build().In(Db);
                    var attention = new NameBuilder(Db).Build().In(Db);

                    new AssociatedNameBuilder(Db)
                    {
                        Name = inheritedName,
                        RelatedName = name,
                        Relationship = relationship,
                        Sequence = seq,
                        ContactName = attention
                    }.Build().In(Db);

                    // send bills to decoy
                    new AssociatedNameBuilder(Db)
                    {
                        Name = name,
                        RelatedName = name,
                        Relationship = KnownRelations.SendBillsTo,
                        ContactName = attention
                    }.Build().In(Db);

                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = name,
                        NameType = nt
                    }.Build().In(Db);

                    cn.InheritedFromNameId = inheritedName.Id;
                    cn.InheritedFromRelationId = relationship;
                    cn.InheritedFromSequence = seq;

                    fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name.Id, attention.Id});

                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.Equal($"{attention.FirstName} {attention.LastName}", r.Single().Attention);
                }

                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldNotReturnFilteredNames(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);

                    var seq = Fixture.Short();
                    var relationship = Fixture.String();
                    var inheritedName = new NameBuilder(Db).Build().In(Db);
                    var name = new NameBuilder(Db).Build().In(Db);
                    var attention = new NameBuilder(Db).Build().In(Db);

                    new AssociatedNameBuilder(Db)
                    {
                        Name = inheritedName,
                        RelatedName = name,
                        Relationship = relationship,
                        Sequence = seq,
                        ContactName = attention
                    }.Build().In(Db);

                    // send bills to decoy
                    new AssociatedNameBuilder(Db)
                    {
                        Name = name,
                        RelatedName = name,
                        Relationship = KnownRelations.SendBillsTo,
                        ContactName = attention
                    }.Build().In(Db);

                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = name,
                        NameType = nt
                    }.Build().In(Db);

                    cn.InheritedFromNameId = inheritedName.Id;
                    cn.InheritedFromRelationId = relationship;
                    cn.InheritedFromSequence = seq;

                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.True(string.IsNullOrWhiteSpace(r.Single().Name));
                    Assert.True(string.IsNullOrWhiteSpace(r.Single().NameAndCode));
                    Assert.True(string.IsNullOrWhiteSpace(r.Single().Attention));
                    Assert.Null(r.Single().AttentionId);
                    Assert.False(r.Single().CanView);
                    Assert.False(r.Single().CanViewAttention);
                }
            }

            public class CorrespondenceAddressScenario : FactBase
            {
                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldStep1ReturnCorrespondenceAddressFromCaseName(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);

                    var n = new NameBuilder(Db).Build().In(Db);
                    var addr = new AddressBuilder().Build().In(Db);
                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = n,
                        NameType = nt,
                        Address = addr
                    }.Build().In(Db);

                    nt.ColumnFlag = KnownNameTypeColumnFlags.DisplayAddress;
                    fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {n.Id});
                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.Equal(addr.Formatted(), r.Single().Address);
                }

                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldStep2ReturnAddressFromInheritedAssociatedNameRelationship(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);

                    nt.ColumnFlag = KnownNameTypeColumnFlags.DisplayAddress;

                    var seq = Fixture.Short();
                    var relationship = Fixture.String();
                    var inheritedName = new NameBuilder(Db).Build().In(Db);
                    var name = new NameBuilder(Db).Build().In(Db);
                    var attn = new NameBuilder(Db).Build().In(Db);
                    var addr = new AddressBuilder().Build().In(Db);

                    new AssociatedNameBuilder(Db)
                    {
                        Name = inheritedName,
                        RelatedName = name,
                        Relationship = relationship,
                        Sequence = seq,
                        Address = addr,
                        ContactName = attn
                    }.Build().In(Db);
                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = name,
                        NameType = nt
                    }.Build().In(Db);

                    cn.InheritedFromNameId = inheritedName.Id;
                    cn.InheritedFromRelationId = relationship;
                    cn.InheritedFromSequence = seq;
                    fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name.Id, attn.Id});
                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.Equal(addr.Formatted(), r.Single().Address);
                }

                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldStep3ReturnAddressDerivedFromUninheritedSendBillsToRelationship(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);

                    nt.ColumnFlag = KnownNameTypeColumnFlags.DisplayAddress;

                    var name = new NameBuilder(Db).Build().In(Db);
                    var attn = new NameBuilder(Db).Build().In(Db);
                    var addr = new AddressBuilder().Build().In(Db);

                    new AssociatedNameBuilder(Db)
                    {
                        Name = name,
                        RelatedName = name,
                        Relationship = KnownRelations.SendBillsTo,
                        Address = addr,
                        ContactName = attn
                    }.Build().In(Db);
                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = name,
                        NameType = nt
                    }.Build().In(Db);

                    fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name.Id, attn.Id});

                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.Equal(addr.Formatted(), r.Single().Address);
                }

                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldStep4ReturnAddressFromMainName(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);

                    nt.ColumnFlag = KnownNameTypeColumnFlags.DisplayAddress;

                    var addr = new AddressBuilder().Build().In(Db);
                    var name = new NameBuilder(Db)
                    {
                        PostalAddress = addr
                    }.Build().In(Db);

                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = name,
                        NameType = nt
                    }.Build().In(Db);
                    fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name.Id});

                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.Equal(addr.Formatted(), r.Single().Address);
                }

                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldPickAddressFromNameTypeInheritanceOverMainName(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);

                    nt.ColumnFlag = KnownNameTypeColumnFlags.DisplayAddress;

                    var seq = Fixture.Short();
                    var relationship = Fixture.String();
                    var inheritedName = new NameBuilder(Db).Build().In(Db);
                    var addr = new AddressBuilder().Build().In(Db);
                    var addrDecoy2 = new AddressBuilder().Build().In(Db);
                    var name = new NameBuilder(Db) {PostalAddress = addrDecoy2}.Build().In(Db);
                    var attn = new NameBuilder(Db).Build().In(Db);

                    new AssociatedNameBuilder(Db)
                    {
                        Name = inheritedName,
                        RelatedName = name,
                        Relationship = relationship,
                        Sequence = seq,
                        Address = addr,
                        ContactName = attn
                    }.Build().In(Db);
                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = name,
                        NameType = nt
                    }.Build().In(Db);

                    cn.InheritedFromNameId = inheritedName.Id;
                    cn.InheritedFromRelationId = relationship;
                    cn.InheritedFromSequence = seq;
                    fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name.Id, attn.Id});

                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.Equal(addr.Formatted(), r.Single().Address);
                }

                [Theory]
                [InlineData(KnownNameTypes.Debtor)]
                [InlineData(KnownNameTypes.RenewalsDebtor)]
                public async Task ShouldPickAddressFromNameTypeInheritanceOverSendBillsToRelationship(string typeCode)
                {
                    var fixture = new CaseViewNamesProviderFixture(Db)
                        .WithNameType(typeCode, out var nt);

                    nt.ColumnFlag = KnownNameTypeColumnFlags.DisplayAddress;

                    var seq = Fixture.Short();
                    var relationship = Fixture.String();
                    var inheritedName = new NameBuilder(Db).Build().In(Db);
                    var name = new NameBuilder(Db).Build().In(Db);
                    var attn = new NameBuilder(Db).Build().In(Db);
                    var addr1 = new AddressBuilder().Build().In(Db);
                    var addr2 = new AddressBuilder().Build().In(Db);

                    new AssociatedNameBuilder(Db)
                    {
                        Name = inheritedName,
                        RelatedName = name,
                        Relationship = relationship,
                        Sequence = seq,
                        Address = addr1,
                        ContactName = attn
                    }.Build().In(Db);

                    // send bills to decoy
                    new AssociatedNameBuilder(Db)
                    {
                        Name = name,
                        RelatedName = name,
                        Relationship = KnownRelations.SendBillsTo,
                        Address = addr2
                    }.Build().In(Db);

                    var cn = new CaseNameBuilder(Db)
                    {
                        Name = name,
                        NameType = nt
                    }.Build().In(Db);

                    cn.InheritedFromNameId = inheritedName.Id;
                    cn.InheritedFromRelationId = relationship;
                    cn.InheritedFromSequence = seq;

                    fixture.NameAuthorization.AccessibleNames().ReturnsForAnyArgs(new[] {name.Id, attn.Id});

                    var r = (await fixture.Subject
                                          .GetNames(cn.CaseId, new[] {typeCode}, Fixture.Integer())).ToArray();

                    Assert.Single(r);
                    Assert.Equal(addr1.Formatted(), r.Single().Address);
                }
            }
        }

        public class CaseViewNamesProviderFixture : IFixture<CaseViewNamesProvider>
        {
            readonly InMemoryDbContext _db;

            public CaseViewNamesProviderFixture(InMemoryDbContext db, bool isExternalUser = false)
            {
                _db = db;

                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User(Fixture.String(), isExternalUser).In(db));

                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                cultureResolver.Resolve().Returns("en");

                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

                formattedNameAddressTelecom = Substitute.For<IFormattedNameAddressTelecom>();
                formattedNameAddressTelecom.GetFormatted(Arg.Any<int[]>(), NameStyles.FirstNameThenFamilyName)
                                           .Returns(x =>
                                           {
                                               var nameIds = ((int[]) x[0]).Distinct();
                                               return (from n in _db.Set<Name>()
                                                       where nameIds.Contains(n.Id)
                                                       select new NameFormatted
                                                       {
                                                           NameId = n.Id,
                                                           Name = n.FirstName + " " + n.LastName,
                                                           NameCode = n.NameCode,
                                                           Nationality = "nationality" + Fixture.String(),
                                                           MainPostalAddressId = n.PostalAddressId,
                                                           MainStreetAddressId = n.StreetAddressId,
                                                           MainPhone = n.MainPhone().FormattedOrNull(),
                                                           MainEmail = n.MainEmail().FormattedOrNull(),
                                                           WebAddress = n.Telecoms == null ? null :
                                                                        Fixture.String()
                                                       })
                                                   .ToDictionary(k => k.NameId, v => v);
                                           });

                formattedNameAddressTelecom.GetAddressesFormatted(Arg.Any<int[]>())
                                           .Returns(x =>
                                           {
                                               var addressId = ((int[]) x[0]).Distinct();
                                               return (from a in _db.Set<Address>()
                                                       where addressId.Contains(a.Id)
                                                       select new AddressFormatted
                                                       {
                                                           Id = a.Id,
                                                           Address = a.Formatted(AddressStyles.Default)
                                                       })
                                                   .ToDictionary(k => k.Id, v => v);
                                           });

                NameAuthorization = Substitute.For<INameAuthorization>();
                Subject = new CaseViewNamesProvider(db, securityContext, NameAuthorization, formattedNameAddressTelecom, cultureResolver, TaskSecurityProvider);
            }

            public ITaskSecurityProvider TaskSecurityProvider { get; set; }

            public INameAuthorization NameAuthorization { get; set; }

            public IFormattedNameAddressTelecom formattedNameAddressTelecom { get; set; }

            public CaseViewNamesProvider Subject { get; }

            public CaseViewNamesProviderFixture WithNameType(string nameTypeCode, out NameType nt, bool isAllowable = true)
            {
                nt = new NameTypeBuilder
                     {
                         NameTypeCode = nameTypeCode,
                         PriorityOrder = (short) _db.Set<NameType>().Count()
                     }
                     .Build()
                     .In(_db);

                if (isAllowable) new FilteredUserNameTypes {NameType = nt.NameTypeCode}.In(_db);

                return this;
            }

            public CaseViewNamesProviderFixture WithCaseName(Case @case, NameType nameType, Name name = null, NameVariant nv = null, Name attn = null, Address addr = null)
            {
                new CaseNameBuilder(_db)
                {
                    Name = name ?? new NameBuilder(_db).Build().In(_db),
                    NameType = nameType,
                    NameVariant = nv,
                    AttentionName = attn,
                    Address = addr
                }.BuildWithCase(@case).In(_db);

                return this;
            }
        }
    }
}