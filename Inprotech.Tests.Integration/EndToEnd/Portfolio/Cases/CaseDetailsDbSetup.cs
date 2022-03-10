using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Drawing;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.Cases.Details.DesignatedJurisdiction;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.KeepOnTopNotes;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.StandingInstructions;
using InprotechKaizen.Model.ValidCombinations;
using Action = InprotechKaizen.Model.Cases.Action;
using Image = InprotechKaizen.Model.Cases.Image;
using NT = InprotechKaizen.Model.KnownNameTypeColumnFlags;
using RelatedCase = InprotechKaizen.Model.Cases.RelatedCase;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    public class CaseDetailsDbSetup : DbSetup
    {
        const string CasePrefix = "e2e";
        const string CriticialDateActionName = CasePrefix + "-CD";
        const string RenewalDisplayActionName = CasePrefix + "-RD";

        bool _isForExternalUser;

        public CaseDetailsDbSetup(IDbContext dbContext = null) : base(dbContext)
        {
        }

        public string CriticalDatesSiteControlId { get; private set; } = SiteControls.CriticalDates_Internal;
        public string ScreenCriteriaProgram { get; private set; } = "CASENTRY";

        public string CpaDateStart { get; private set; } = SiteControls.CPADate_Start;

        public string CpaDateStop { get; private set; } = SiteControls.CPADate_Stop;

        public string RenewalInstructionTypeCode { get; } = "R";

        public string ExaminationInstructionTypeCode { get; } = "E";

        public ScreenCriteriaBuilder GetScreenCriteriaBuilder(Case @case, string internalProgram = KnownCasePrograms.CaseEntry)
        {
            return _isForExternalUser
                ? new ScreenCriteriaBuilder(DbContext).Create(@case, out _, KnownCasePrograms.ClientAccess)
                : new ScreenCriteriaBuilder(DbContext).Create(@case, out _, internalProgram);
        }

        public dynamic NavigationDataSetup()
        {
            var trademark = DbContext.Set<PropertyType>().Single(vq => vq.Code == KnownPropertyTypes.TradeMark);
            var patent = DbContext.Set<PropertyType>().Single(vq => vq.Code == KnownPropertyTypes.Patent);
            var case1 = new CaseBuilder(DbContext).Create(CasePrefix + "1", true);
            var case2 = new CaseBuilder(DbContext).Create(CasePrefix + "2", true);
            var case3 = new CaseBuilder(DbContext).Create(CasePrefix + "3", true);

            case1.PropertyType = trademark;
            case2.PropertyType = patent;

            case1.Title = Fixture.String(5);
            case2.Title = Fixture.String(5);
            case3.Title = Fixture.String(5);

            DbContext.SaveChanges();

            return new
            {
                CasePrefix,
                Case1 = case1,
                Case2 = case2
            };
        }

        public dynamic ReadOnlyDataSetup(bool forExternalUser = false)
        {
            if (forExternalUser)
            {
                _isForExternalUser = true;
                CriticalDatesSiteControlId = SiteControls.CriticalDates_External;
                ScreenCriteriaProgram = KnownCasePrograms.ClientAccess;
            }

            /**
            * Trademark - Pending, Names, Critical Dates, Actions, Events
            **/
            var country = new Country
            {
                Id = Fixture.String(3),
                Name = Fixture.String(10),
                Type = "0",
                CountryAdjective = Fixture.String(10),
                AddressStyleId = (int)AddressStyles.CityBeforePostCodeFullState
            };
            var pendingTrademark = new CaseBuilder(DbContext).Create(CasePrefix + "T1", true, null, country);
            var nameType1 = InsertWithNewId(new NameType { Name = Fixture.String(10), PriorityOrder = 80 });
            var name = new NameBuilder(DbContext).CreateClientIndividual("1-");

            var nameType2 = InsertWithNewId(new NameType { Name = Fixture.String(10), PriorityOrder = -1 });
            var name2A = new NameBuilder(DbContext).CreateClientIndividual("2A");
            var name2B = new NameBuilder(DbContext).CreateClientIndividual("2B");
            var nameType3 = InsertWithNewId(new NameType { Name = Fixture.String(10), PriorityOrder = 90, NationalityFlag = true });
            var name3A = new NameBuilder(DbContext).CreateClientIndividual("3C");
            var attn = new NameBuilder(DbContext).CreateClientIndividual("attn");

            var billingOrg = new NameBuilder(DbContext).CreateClientOrg("BIL");
            var billingOrgContact = new NameBuilder(DbContext).CreateClientIndividual("BIL-C");
            var d = pendingTrademark.CaseNames.Single(_ => _.NameTypeId == KnownNameTypes.Debtor);
            var renewalDebtorNameType = DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.RenewalsDebtor);
            var renewalInstructorNameType = DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.RenewalsInstructor);

            var debtorNameType = DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Debtor);
            debtorNameType.IsNameRestricted = 0;

            var addressAndTelecom = DbContext.Set<TableCode>()
                                             .Where(_ => _.Id == (int)KnownAddressTypes.PostalAddress || _.Id == (int)KnownTelecomTypes.Telephone || _.Id == (int)KnownTelecomTypes.Email || _.Id == (int)KnownTelecomTypes.Website)
                                             .ToDictionary(k => k.Id, v => v);

            // Set up debtor restrictions flag for Billing Org so that the icon displays
            // Contingent on the RenewalDebtorNameType also has the Show Restriction Flag turned on, that will be set up at Case View.
            var clientDetail = Insert(new ClientDetail(billingOrg.Id));
            clientDetail.DebtorStatus = InsertWithNewId(new DebtorStatus(KnownDebtorRestrictions.DisplayError)
            {
                RestrictionType = KnownDebtorRestrictions.DisplayError,
                Status = Fixture.String(20)
            });

            nameType2.ColumnFlag = NT.DisplayAddress | NT.DisplayReferenceNumber | NT.DisplayAttention | NT.DisplayBillPercentage;
            var addr = InsertWithNewId(new Address { Country = country, City = Fixture.String(10), PostCode = Fixture.String(5), Street1 = Fixture.String(20) });
            Insert(new NameAddress(name2A, addr, addressAndTelecom[(int)KnownAddressTypes.PostalAddress]));
            var teleName = new Telecommunication { TelecomNumber = "nameMain@somewhere.com", TelecomType = addressAndTelecom[(int)KnownTelecomTypes.Email] };
            var teleAttention = new Telecommunication { TelecomNumber = "nameAttn@somewhere.com", TelecomType = addressAndTelecom[(int)KnownTelecomTypes.Email] };
            var email = InsertWithNewId(teleName);
            var emailAttn = InsertWithNewId(teleAttention);

            var websiteName = InsertWithNewId(new Telecommunication { TelecomNumber = "www.somewhere.com", TelecomType = addressAndTelecom[(int)KnownTelecomTypes.Website] });
            var phoneMain = InsertWithNewId(new Telecommunication
            {
                TelecomNumber = "1234 5678",
                Isd = "+61",
                AreaCode = "2",
                Extension = "3000",
                TelecomType = addressAndTelecom[(int)KnownTelecomTypes.Telephone]
            });
            name2B.MainEmailId = email.Id;
            name2B.MainPhoneId = phoneMain.Id;
            attn.MainEmailId = emailAttn.Id;
            Insert(new NameTelecom(name2B, email));
            Insert(new NameTelecom(attn, emailAttn));
            Insert(new NameTelecom(name2B, phoneMain));
            Insert(new NameTelecom(name2B, websiteName));

            name2A.PostalAddressId = addr.Id;
            name2A.MainContact = attn;
            nameType3.ColumnFlag = NT.DisplayAssignDate | NT.DisplayBillPercentage | NT.DisplayDateCeased | NT.DisplayDateCommenced | NT.DisplayRemarks;

            pendingTrademark.Title = Fixture.UriSafeString(20);
            pendingTrademark.PropertyType = DbContext.Set<PropertyType>().Single(vq => vq.Code == KnownPropertyTypes.TradeMark);
            pendingTrademark.CaseStatus = DbContext.Set<Status>().Add(new Status(Fixture.Short(), Fixture.String(5)) { RegisteredFlag = 0m, LiveFlag = 1m }); /* Pending Status */

            var startEv = new EventBuilder(DbContext).Create();
            var stopEv = new EventBuilder(DbContext).Create();

            var cpaDateStartSiteControl = DbContext.Set<SiteControl>().Single(_ => _.ControlId == CpaDateStart);
            cpaDateStartSiteControl.StringValue = startEv.Id.ToString();

            var cpaDateStopSiteControl = DbContext.Set<SiteControl>().Single(_ => _.ControlId == CpaDateStop);
            cpaDateStopSiteControl.StringValue = stopEv.Id.ToString();
            DbContext.SaveChanges();

            Insert(new CaseEvent(pendingTrademark.Id, startEv.Id, 1)
            {
                EventDate = DateTime.Today.AddYears(-2),
                IsOccurredFlag = 1
            });
            Insert(new CaseEvent(pendingTrademark.Id, stopEv.Id, 1)
            {
                EventDate = DateTime.Today.AddYears(-3),
                IsOccurredFlag = 1
            });
            DbContext.SaveChanges();

            InsertWithNewId(new CpaSend { CaseId = pendingTrademark.Id });
            Insert(new CpaSend(pendingTrademark, 1, DateTime.Now.AddYears(-1), "T"));
            DbContext.SaveChanges();

            InsertWithNewId(new CpaEvent { CefNo = 23232, BatchNo = 1 });
            Insert(new CpaEvent(pendingTrademark, 23232, DateTime.Now.AddYears(-2), "IV", 1));
            DbContext.SaveChanges();

            InsertWithNewId(new CpaPortfolio { CaseId = pendingTrademark.Id, Id = 3223 });
            Insert(new CpaPortfolio(pendingTrademark, DateTime.Now.AddYears(-3), "L"));
            DbContext.SaveChanges();

            // cn2 and cn3 both share the same name type that shows address and attention.
            // cn2 will get address from cn2.Name.PostalAddressId but won't get cn2.Name.MainContact
            // cn3 will get address and attention from cn3.AddressId and cn3.AttentionNameId
            var cn1 = new CaseName(pendingTrademark, nameType1, name, 1);
            var cn2 = new CaseName(pendingTrademark, nameType2, name2A, 1);
            var cn3 = new CaseName(pendingTrademark, nameType2, name2B, 1, address: addr, attentionName: attn);
            var cn4 = new CaseName(pendingTrademark, nameType3, name3A, 1);
            var rd = new CaseName(pendingTrademark, renewalDebtorNameType, billingOrg, 1);
            var rdc = new CaseName(pendingTrademark, renewalDebtorNameType, billingOrgContact, 1);
            var ri = new CaseName(pendingTrademark, renewalInstructorNameType, name2A, 1);
            pendingTrademark.CaseNames.AddRange(new[] { cn1, cn2, cn3, cn4, rd, rdc, ri });

            // debtor will derive from inherited association
            // renewal debtor will derive from send bills to relationship
            var relation = InsertWithNewId(new NameRelation { RelationDescription = Fixture.String(20), ReverseDescription = Fixture.String(20) }, x => x.RelationshipCode);
            d.InheritedFromRelationId = relation.RelationshipCode;
            d.InheritedFromNameId = billingOrg.Id;
            d.InheritedFromSequence = d.Sequence;
            d.IsInherited = 1;

            var debtor = d.Name;
            var phone = InsertWithNewId(new Telecommunication
            {
                TelecomNumber = "1234 5678",
                Isd = "+61",
                AreaCode = "2",
                Extension = "3000",
                TelecomType = addressAndTelecom[(int)KnownTelecomTypes.Telephone]
            });
            Insert(new NameTelecom(debtor, phone));
            debtor.MainPhoneId = phone.Id;

            Insert(new NameTelecom(debtor, email));
            debtor.MainEmailId = email.Id;
            d.Remarks = Fixture.String(20);

            // mark the attention name derived.
            cn3.IsDerivedAttentionName = 1;

            // for name3A, set to display the following fields
            var canadian = DbContext.Set<Country>().Single(_ => _.Id == "CA");
            name3A.Nationality = canadian;

            cn4.Remarks = Fixture.String(20, 5);
            cn4.ExpiryDate = Fixture.Today();
            cn4.StartingDate = Fixture.PastDate();
            cn4.AssignmentDate = Fixture.PastDate();
            cn4.BillingPercentage = 100;

            Insert(new AssociatedName(billingOrg, d.Name, relation.RelationshipCode, d.Sequence) { ContactId = billingOrgContact.Id });
            Insert(new AssociatedName(billingOrg, billingOrg, KnownRelations.SendBillsTo, 1) { ContactId = billingOrgContact.Id });

            const string longTextLoremIpsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur vel sapien tortor. The END";

            var designElem1 = Insert(new DesignElement(pendingTrademark.Id, 1) { FirmElementId = "Firm Element Ref1" });
            var designElem2 = Insert(new DesignElement(pendingTrademark.Id, 2) { FirmElementId = "Firm Element Ref2" });
            var imageType = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.ImageTypeForCaseHeader).IntegerValue;
            var png1 = Fixture.Image(500, 500, Color.Black);
            var image1 = InsertWithNewId(new Image { ImageData = png1 });
            Insert(new CaseImage(pendingTrademark, image1.Id, 0, imageType.GetValueOrDefault(1201)) { CaseImageDescription = "Trade Mark Image 1" + longTextLoremIpsum, FirmElementId = designElem1.FirmElementId });
            var png2 = Fixture.Image(500, 500, Color.Red);
            var image2 = InsertWithNewId(new Image { ImageData = png2 });
            Insert(new CaseImage(pendingTrademark, image2.Id, 1, imageType.GetValueOrDefault(1201)) { CaseImageDescription = "Trade Mark Image 2" });
            var png3 = Fixture.Image(500, 500, Color.AntiqueWhite);
            var image3 = InsertWithNewId(new Image { ImageData = png3 });
            Insert(new CaseImage(pendingTrademark, image3.Id, 2, imageType.GetValueOrDefault(1201)) { CaseImageDescription = "Trade Mark Image 3", FirmElementId = designElem2.FirmElementId });
            var png4 = Fixture.Image(500, 500, Color.Azure);
            var image4 = InsertWithNewId(new Image { ImageData = png4 });
            Insert(new CaseImage(pendingTrademark, image4.Id, 3, imageType.GetValueOrDefault(1201)) { CaseImageDescription = "Trade Mark Image 4" });
            var png5 = Fixture.Image(500, 500, Color.AliceBlue);
            var image5 = InsertWithNewId(new Image { ImageData = png5 });
            Insert(new CaseImage(pendingTrademark, image5.Id, 4, imageType.GetValueOrDefault(1201)) { CaseImageDescription = "Trade Mark Image 5" });
            var png6 = Fixture.Image(500, 500, Color.BlueViolet);
            var image6 = InsertWithNewId(new Image { ImageData = png6 });
            Insert(new CaseImage(pendingTrademark, image6.Id, 5, imageType.GetValueOrDefault(1201)) { CaseImageDescription = "Trade Mark Image 6" });
            var png7 = Fixture.Image(500, 500, Color.Beige);
            var image7 = InsertWithNewId(new Image { ImageData = png7 });
            Insert(new CaseImage(pendingTrademark, image7.Id, 6, imageType.GetValueOrDefault(1201)) { CaseImageDescription = "Trade Mark Image 7" });
            var png8 = Fixture.Image(500, 500, Color.Brown);
            var image8 = InsertWithNewId(new Image { ImageData = png8 });
            Insert(new CaseImage(pendingTrademark, image8.Id, 7, imageType.GetValueOrDefault(1201)) { CaseImageDescription = "Trade Mark Image 8" });
            var png9 = Fixture.Image(500, 500, Color.Brown);
            var image9 = InsertWithNewId(new Image { ImageData = png9 });
            Insert(new CaseImage(pendingTrademark, image9.Id, 8, imageType.GetValueOrDefault(1201)) { CaseImageDescription = "Trade Mark Image 9" });

            var officialNumbersTradeMark = OfficialNumbers(pendingTrademark);

            var namesBuilder1 = new TopicControlBuilder(KnownCaseScreenTopics.Names + "_cloned_" + RandomString.Next(5), "NameTypeKey", nameType2.NameTypeCode);
            var namesBuilder2 = new TopicControlBuilder(KnownCaseScreenTopics.Names + "_cloned_" + RandomString.Next(5), "NameTypeKey", nameType3.NameTypeCode);

            var textBuilder1 = new TopicControlBuilder(KnownCaseScreenTopics.CaseTexts + "_cloned_" + RandomString.Next(5), "TextTypeKey", "M");
            var textBuilder2 = new TopicControlBuilder(KnownCaseScreenTopics.CaseTexts + "_cloned_" + RandomString.Next(5), "TextTypeKey", "T");
            var textBuilder3 = new TopicControlBuilder(KnownCaseScreenTopics.CaseTexts + "_cloned_" + RandomString.Next(5), "TextTypeKey", "D")
            {
                TopicTitle = "Descriptions"
            };
            var goodsServices = new TopicControlBuilder(KnownCaseScreenTopics.CaseTexts + "_cloned_" + RandomString.Next(5), "TextTypeKey", "G")
            {
                TopicTitle = "Goods Services"
            };

            var builder = new DataItemBuider(DbContext);
            var docItem = builder.Create(0, "select 'https://www.cpaglobal.com', 'Cpa Global', 'className'", "Custom_Content", "custom content doc item");

            var customContentBuilder1 = new TopicControlBuilder(KnownCaseScreenTopics.CaseCustomContent + "_cloned_" + RandomString.Next(5), "ItemKey", docItem.Id.ToString());
            var customContentBuilder2 = new TopicControlBuilder(KnownCaseScreenTopics.CaseCustomContent + "_cloned_" + RandomString.Next(5), "CustomContentUrl", "abcd")
            {
                TopicTitle = "Custom Content 2"
            };

            var trademarkLabel = Fixture.Prefix("Trademark");
            GetScreenCriteriaBuilder(pendingTrademark, KnownCasePrograms.CaseEnquiry)
                .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                .WithTopicControl(KnownCaseScreenTopics.Image)
                .WithTopicControl(KnownCaseScreenTopics.Names);

            GetScreenCriteriaBuilder(pendingTrademark)
                .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                .WithTopicControl(KnownCaseScreenTopics.Image)
                .WithTopicControl(KnownCaseScreenTopics.CriticalDates)
                .WithTopicControl(KnownCaseScreenTopics.Events)
                .WithTopicControl(KnownCaseScreenTopics.Names)
                .WithTopicControl(KnownCaseScreenTopics.Classes)
                .WithTopicControl(KnownCaseScreenTopics.RelatedCases)
                .WithTopicControl(KnownCaseScreenTopics.OfficialNumbers)
                .WithTopicControl(KnownCaseScreenTopics.Efiling)
                .WithTopicControl(KnownCaseScreenTopics.Images)
                .WithTopicControl(KnownCaseScreenTopics.CaseRenewals)
                .WithTopicControl(KnownCaseScreenTopics.CaseStandingInstructions)
                .WithTopicControl(KnownCaseScreenTopics.DesignElement)
                .WithTopicControl(KnownCaseScreenTopics.FileLocations)
                .WithTopicControl(KnownCaseScreenTopics.Checklist)
                .WithTopicControlsInTab("CustomContent_1", "CustomContent_1", customContentBuilder1)
                .WithTopicControlsInTab("CustomContent_2", "CustomContent_2", customContentBuilder2)
                .WithTopicControlsInTab("CombinedText", "CombinedText", textBuilder1, textBuilder2)
                .WithTopicControlsInTab("Descriptions", "Descriptions", textBuilder3)
                .WithTopicControlsInTab("CombinedNames", "CombinedNames", namesBuilder1, namesBuilder2)
                .WithTopicControlsInTab("GoodsServices", "Goods Services", goodsServices)
                .WithElementControl(KnownCaseScreenTopics.CaseHeader, "lblCaseReference", trademarkLabel)
                .WithElementControl(KnownCaseScreenTopics.CaseHeader, "lblRenewalStatusDescription", string.Empty);

            var anotherTrademark = new CaseBuilder(DbContext).Create(CasePrefix + "T2", true, null, country);
            anotherTrademark.Title = Fixture.String(5);
            anotherTrademark.PropertyType = DbContext.Set<PropertyType>().Single(vq => vq.Code == KnownPropertyTypes.TradeMark);
            anotherTrademark.CaseStatus = DbContext.Set<Status>().Add(new Status(Fixture.Short(), Fixture.String(5)) { RegisteredFlag = 0m, LiveFlag = 1m }); /* Pending Status */
            anotherTrademark.CaseNames.Add(new CaseName(anotherTrademark, nameType1, name, 1));

            var rc = FileConventionClaimSetup(anotherTrademark, pendingTrademark);

            /**
            * Patent, Dead, Critical Dates
            **/
            var deadPatent = new CaseBuilder(DbContext).Create(CasePrefix + "P1", true);
            deadPatent.Title = Fixture.String(5);
            deadPatent.PropertyType = DbContext.Set<PropertyType>().Single(vq => vq.Code == KnownPropertyTypes.Patent);
            deadPatent.CaseStatus = DbContext.Set<Status>().Add(new Status(Fixture.Short(), Fixture.String(5)) { RegisteredFlag = 0m, LiveFlag = 0m }); /* Dead status */

            var patentLabel = Fixture.Prefix("Patent");
            GetScreenCriteriaBuilder(deadPatent)
                .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                .WithTopicControl(KnownCaseScreenTopics.Image)
                .WithTopicControl(KnownCaseScreenTopics.CriticalDates)
                .WithTopicControl(KnownCaseScreenTopics.RelatedCases)
                .WithTopicControl(KnownCaseScreenTopics.OfficialNumbers)
                .WithTopicControl(KnownCaseScreenTopics.DesignatedJurisdiction)
                .WithTopicControl(KnownCaseScreenTopics.CaseTexts)
                .WithTopicControl(KnownCaseScreenTopics.CaseRenewals)
                .WithElementControl(KnownCaseScreenTopics.CaseHeader, "lblCaseReference", patentLabel)
                .WithElementControl(KnownCaseScreenTopics.CaseHeader, "lblNoInSeries", string.Empty, true)
                .WithElementControl(KnownCaseScreenTopics.CaseHeader, "lblClasses", string.Empty, true)
                .WithElementControl(KnownCaseScreenTopics.CaseHeader, "lblTypeOfMarkDescription", string.Empty, true)
                .WithElementControl(KnownCaseScreenTopics.CaseHeader, "lblRenewalStatusDescription", string.Empty);

            var criticalDatesAndEvents = CriticalDatesAndEventsSetup(pendingTrademark, deadPatent);
            var officialNumbersPatent = OfficialNumbers(deadPatent);
            var patentTexts = PatentTextSetup(deadPatent);
            var trademarkTexts = TrademarkTextSetup(pendingTrademark, new Dictionary<string, string>
            {
                {"CombinedText", $"Case_TextTopic__{textBuilder1.TabId}"},
                {"Descriptions", $"Case_TextTopic__{textBuilder3.TabId}"},
                {"GoodsServices", $"Case_TextTopic__{goodsServices.TabId}"}
            });

            var designatedJurisdiction = DesignatedJurisdictionSetup(deadPatent, _isForExternalUser);

            var relevantDates = SetupRenewalDetailsAndEvents(pendingTrademark).ToArray();
            var renewalInstructions = SetupRenewalStandingInstructions();
            var ipplatformRenewLink = SetupRenewLinkData(deadPatent);
            var standingInstructions = new[] { SetupStandingInstructions(pendingTrademark), renewalInstructions };
            var designElements = SetupDesignElementAndCaseImage(pendingTrademark);
            var fileLocations = SetupCaseFileLocations(pendingTrademark);
            var checklists = SetupChecklists(pendingTrademark);

            DbContext.SaveChanges();

            var relatedCases = RelatedCasesSetup(deadPatent, pendingTrademark);

            var nameTypes = DbContext.Set<NameType>().Where(_ => new[] { nameType2.NameTypeCode, nameType3.NameTypeCode }.Contains(_.NameTypeCode)).ToDictionary(k => k.NameTypeCode, v => v);

            return new
            {
                CasePrefix,
                Trademark = new
                {
                    Case = pendingTrademark,
                    criticalDatesAndEvents[pendingTrademark].CriticalDates,
                    criticalDatesAndEvents[pendingTrademark].Events,
                    criticalDatesAndEvents[pendingTrademark].EventsDue,
                    TrademarkLabel = trademarkLabel,
                    NameType = nameType1,
                    OfficialNumbers = new
                    {
                        IpOffice = officialNumbersTradeMark.ipOfficeNumber,
                        Other = officialNumbersTradeMark.otherNumber
                    },
                    RelatedCases = new
                    {
                        Row1 = new
                        {
                            Relationship = relatedCases.Priority,
                            CaseRef = string.Empty,
                            OfficialNumber = criticalDatesAndEvents[pendingTrademark].CriticalDates.Row1.PriorityNumber,
                            Jurisdiction = criticalDatesAndEvents[pendingTrademark].CriticalDates.Row1.PriorityCountry,
                            Date = criticalDatesAndEvents[pendingTrademark].CriticalDates.Row1.PriorityDate
                        },
                        Row2 = rc.FCF
                    },
                    CaseTexts = trademarkTexts,
                    CaseNames = new
                    {
                        CombinedNames = new
                        {
                            TopicContextKey = $"Names_Component__{namesBuilder1.TabId}",
                            Row1 = new
                            {
                                BillingPercentage = (int?)null,
                                name2A.NameCode,
                                nameTypes[nameType2.NameTypeCode].NameTypeCode,
                                Type = nameTypes[nameType2.NameTypeCode].Name,
                                name2A.FirstName
                            },
                            Row2 = new
                            {
                                BillingPercentage = (int?)null,
                                name2B.NameCode,
                                nameTypes[nameType2.NameTypeCode].NameTypeCode,
                                Type = nameTypes[nameType2.NameTypeCode].Name,
                                attentionNameCode = attn.NameCode,
                                nameEmail = teleName.TelecomNumber,
                                attnEmail = teleAttention.TelecomNumber,
                                phoneMain.TelecomNumber,
                                name2B.FirstName,
                                attentionFirstName = attn.FirstName
                            },
                            Row3 = new
                            {
                                Type = nameTypes[nameType3.NameTypeCode].Name,
                                name3A.FirstName,
                                cn4.Remarks,
                                CeaseDate = $"{cn4.ExpiryDate:dd-MMM-yyyy}",
                                CommenceDate = $"{cn4.StartingDate:dd-MMM-yyyy}",
                                AssignmentDate = $"{cn4.AssignmentDate:dd-MMM-yyyy}",
                                BillingPercentage = $"{cn4.BillingPercentage:####}",
                                Nationality = canadian.CountryAdjective
                            }
                        },
                        Others = new
                        {
                            Row0 = new
                            {
                                Type = nameTypes[nameType2.NameTypeCode].Name,
                                FormattedName = name2A.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName),
                                FormattedAddress = addr.Formatted(),
                                FormattedAttentionName = string.Empty,
                                IsAddressInherited = true,
                                IsAttentionNameDerived = false,
                                IsInherited = false,
                                DebtorStatus = (string)null,
                                Email = string.Empty,
                                EmailHref = string.Empty,
                                Phone = string.Empty,
                                Remarks = string.Empty,
                                Website = string.Empty
                            },
                            Row1 = new
                            {
                                Type = nameTypes[nameType2.NameTypeCode].Name,
                                FormattedName = name2B.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName),
                                FormattedAddress = addr.Formatted(),
                                FormattedAttentionName = attn.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName),
                                IsAddressInherited = false,
                                IsAttentionNameDerived = true,
                                IsInherited = false,
                                DebtorStatus = (string)null,
                                Email = teleAttention.TelecomNumber,
                                EmailHref = $"mailto:{teleAttention.TelecomNumber}?subject={Uri.EscapeDataString($"Regarding Reference: {pendingTrademark.Irn}")}&body={Uri.EscapeDataString($"Regarding Reference: {pendingTrademark.Irn}")}",
                                Phone = "+61 2 1234 5678 x3000",
                                Remarks = string.Empty,
                                Website = websiteName.TelecomNumber
                            },
                            DebtorRow = new
                            {
                                Type = d.NameType.Name,
                                FormattedName = d.NameType.Format(d.Name, NameStyles.FirstNameThenFamilyName),
                                FormattedAddress = d.Name.PostalAddress().Formatted(),
                                FormattedAttentionName = billingOrgContact.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName),
                                IsAddressInherited = true,
                                IsAttentionNameDerived = false,
                                IsInherited = true,
                                DebtorStatus = (string)null,
                                Email = teleName.TelecomNumber,
                                EmailHref = $"mailto:{teleName.TelecomNumber}?subject={Uri.EscapeDataString($"Regarding Reference: {pendingTrademark.Irn}")}&body={Uri.EscapeDataString($"Regarding Reference: {pendingTrademark.Irn}")}",
                                Phone = "+61 2 1234 5678 x3000",
                                d.Remarks,
                                Website = string.Empty
                            },
                            RenewalDebtorRow = new
                            {
                                Type = rd.NameType.Name,
                                FormattedName = rd.NameType.Format(rd.Name, NameStyles.FirstNameThenFamilyName),
                                FormattedAddress = rd.Name.PostalAddress().Formatted(),
                                FormattedAttentionName = billingOrgContact.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName),
                                IsAttentionNameDerived = false,
                                IsAddressInherited = true,
                                IsInherited = false,
                                DebtorStatus = "error",
                                Email = string.Empty,
                                EmailHref = string.Empty,
                                Phone = string.Empty,
                                Remarks = string.Empty,
                                Website = string.Empty
                            }
                        }
                    },
                    RenewalDetailsReleventDates = relevantDates,
                    RenewalInstructions = renewalInstructions,
                    StandingInstructions = standingInstructions,
                    DesignElements = designElements,
                    FileLocations = fileLocations,
                    CustomContent = new
                    {
                        CustomContentValidTopic = customContentBuilder1.TopicName,
                        CustomContentInValidTopic = customContentBuilder2.TopicName
                    },
                    Checklists = checklists,
                    RestrictedName = rd
                },
                Patent = new
                {
                    Case = deadPatent,
                    PatentLabel = patentLabel,
                    criticalDatesAndEvents[deadPatent].CriticalDates,
                    OfficialNumbers = new
                    {
                        IpOffice = officialNumbersPatent.ipOfficeNumber,
                        Other = officialNumbersPatent.otherNumber
                    },
                    RelatedCases = new
                    {
                        Row1 = new
                        {
                            Relationship = relatedCases.Priority,
                            CaseRef = string.Empty,
                            OfficialNumber = criticalDatesAndEvents[deadPatent].CriticalDates.Row1.PriorityNumber,
                            Jurisdiction = criticalDatesAndEvents[deadPatent].CriticalDates.Row1.PriorityCountry,
                            Date = criticalDatesAndEvents[deadPatent].CriticalDates.Row1.PriorityDate
                        },
                        Row2 = relatedCases.P1,
                        Row3 = relatedCases.C1,
                        Row4 = relatedCases.C2,
                        Row5 = relatedCases.P2
                    },
                    DesignatedJurisdiction = designatedJurisdiction,
                    CaseTexts = forExternalUser
                        ? patentTexts.ExternalUserCaseText
                        : patentTexts.InternalUserCaseText,
                    IpplatformRenewLink = ipplatformRenewLink
                }
            };
        }

        public dynamic ReadyOnlyDataSetupAfter14(bool forExternalUser = false)
        {
            var data = ReadOnlyDataSetup(forExternalUser);
            var textBuilder = new TopicControlBuilder(KnownCaseScreenTopics.CaseTexts + "_cloned_" + RandomString.Next(5), "TextTypeKey", "M");
            TrademarkClassesSetup(data.Trademark.Case, new Dictionary<string, string>
            {
                {"Classes", $"Case_ClassesTopic__{textBuilder.TabId}"}
            });

            return data;
        }

        dynamic PatentTextSetup(Case currentCase)
        {
            // use underscore to ensure it appears before everything else.
            var textTypeNotAvailableToExternal = InsertWithNewAlphaNumericId(new TextType("___" + RandomString.Next(20))
            {
                UsedByFlag = (short)KnownTextTypeUsedBy.Case
            });

            var ct1 = Insert(new CaseText(currentCase.Id, textTypeNotAvailableToExternal.Id, 0, null)
            {
                Text = RandomString.Next(100) + Environment.NewLine + RandomString.Next(100),
                ModifiedDate = DateTime.Today
            });

            var clientTextTypes = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.ClientTextTypes).StringValue.Split(',');
            DbContext.SaveChanges();
            var availableToExternalUser = DbContext.Set<TextType>()
                                                   .Where(_ => _.UsedByFlag != null && clientTextTypes.Contains(_.Id))
                                                   .First(_ => ((short)_.UsedByFlag & (short)KnownTextTypeUsedBy.Case) == (short)KnownTextTypeUsedBy.Case);

            // Will not display because this is an older text for the case for the given text type
            Insert(new CaseText(currentCase.Id, availableToExternalUser.Id, 0, null)
            {
                Text = RandomString.Next(100) + Environment.NewLine + RandomString.Next(100),
                ModifiedDate = DateTime.Today.AddDays(-1)
            });

            var languages = DbContext.Set<TableCode>().Where(_ => _.TableTypeId == (int)TableTypes.Language).OrderBy(_ => _.Name).ToArray();

            // Will display because this is the newer text for the case for the given text type
            var willDisplay1 = Insert(new CaseText(currentCase.Id, availableToExternalUser.Id, 1, null)
            {
                Text = "<span><strong>" + RandomString.Next(20) + RandomString.Next(20) + "</strong></span>",
                ModifiedDate = DateTime.Today
            });

            var willDisplay2 = Insert(new CaseText(currentCase.Id, availableToExternalUser.Id, 2, null)
            {
                Text = RandomString.Next(20) + Environment.NewLine + RandomString.Next(20),
                ModifiedDate = DateTime.Today,
                Language = languages.First().Id
            });

            var willDisplay3 = Insert(new CaseText(currentCase.Id, availableToExternalUser.Id, 3, null)
            {
                Text = RandomString.Next(20) + Environment.NewLine + RandomString.Next(20),
                ModifiedDate = DateTime.Today,
                Language = languages.Last().Id
            });

            return new
            {
                InternalUserCaseText = new
                {
                    Row1 = new
                    {
                        Type = ct1.TextType.TextDescription,
                        Notes = ct1.Text,
                        Language = (string)null
                    },
                    Row2 = new
                    {
                        Type = willDisplay1.TextType.TextDescription,
                        Notes = willDisplay1.Text.Replace("<span><strong>", string.Empty).Replace("</strong></span>", string.Empty),
                        Language = (string)null
                    },
                    Row3 = new
                    {
                        Type = willDisplay2.TextType.TextDescription,
                        Notes = willDisplay2.Text,
                        Language = languages.Single(_ => _.Id == willDisplay2.Language).Name
                    },
                    Row4 = new
                    {
                        Type = willDisplay3.TextType.TextDescription,
                        Notes = willDisplay3.Text,
                        Language = languages.Single(_ => _.Id == willDisplay3.Language).Name
                    }
                },
                ExternalUserCaseText = new
                {
                    Row1 = new
                    {
                        Type = willDisplay1.TextType.TextDescription,
                        Notes = willDisplay1.Text,
                        Language = (string)null
                    },
                    Row2 = new
                    {
                        Type = willDisplay2.TextType.TextDescription,
                        Notes = willDisplay2.Text,
                        Language = languages.Single(_ => _.Id == willDisplay2.Language).Name
                    },
                    Row3 = new
                    {
                        Type = willDisplay3.TextType.TextDescription,
                        Notes = willDisplay3.Text,
                        Language = languages.Single(_ => _.Id == willDisplay3.Language).Name
                    }
                }
            };
        }

        void TrademarkClassesSetup(Case currentCase, Dictionary<string, string> contexts)
        {
            var class01 = InsertWithNewId(new TmClass(currentCase.CountryId, "L1", currentCase.PropertyTypeId));

            InsertWithNewId(new ClassItem("Undefined01", "Undefined item for class 01", null, class01.Id));
        }

        dynamic TrademarkTextSetup(Case currentCase, Dictionary<string, string> contexts)
        {
            var textTypes = DbContext.Set<TextType>().Where(_ => new[] { "T", "M", "D", "G" }.Contains(_.Id)).ToDictionary(k => k.Id, v => v);

            var titleOrFullMark = Insert(new CaseText(currentCase.Id, "T", 0, null)
            {
                Text = RandomString.Next(100) + Environment.NewLine + RandomString.Next(100),
                ModifiedDate = DateTime.Today
            });

            var translationsOfTrademark = Insert(new CaseText(currentCase.Id, "M", 0, null)
            {
                Text = RandomString.Next(100) + Environment.NewLine + RandomString.Next(100),
                ModifiedDate = DateTime.Today.AddDays(-1)
            });

            var descriptions = Insert(new CaseText(currentCase.Id, "D", 0, null)
            {
                Text = RandomString.Next(100) + Environment.NewLine + RandomString.Next(100),
                ModifiedDate = DateTime.Today.AddDays(-1)
            });

            var goodsServices1 = Insert(new CaseText(currentCase.Id, "G", 1, null)
            {
                Text = RandomString.Next(20),
                ModifiedDate = DateTime.Today
            });

            var goodsServices2 = Insert(new CaseText(currentCase.Id, "G", 3, null)
            {
                Text = goodsServices1.Text + RandomString.Next(20),
                ModifiedDate = DateTime.Today
            });

            var goodsServices3 = Insert(new CaseText(currentCase.Id, "G", 4, "L1")
            {
                Language = 4704,
                Text = goodsServices1.Text + RandomString.Next(20),
                ModifiedDate = DateTime.Today
            });

            var goodsServices4 = Insert(new CaseText(currentCase.Id, "G", 5, "L1")
            {
                Language = 4707,
                Text = goodsServices1.Text + RandomString.Next(20),
                ModifiedDate = DateTime.Today
            });

            return new
            {
                CombinedText = new
                {
                    TopicContextKey = contexts["CombinedText"],
                    Row1 = new
                    {
                        Type = textTypes["T"].TextDescription,
                        Notes = titleOrFullMark.Text,
                        Language = (string)null
                    },
                    Row2 = new
                    {
                        Type = textTypes["M"].TextDescription,
                        Notes = translationsOfTrademark.Text,
                        Language = (string)null
                    }
                },
                FilteredText = new
                {
                    TopicContextKey = contexts["Descriptions"],
                    Row1 = new
                    {
                        Type = textTypes["D"].TextDescription,
                        Notes = descriptions.Text,
                        Language = (string)null
                    }
                },
                GoodsServices = new
                {
                    TopicContextKey = contexts["GoodsServices"],
                    Row1 = new
                    {
                        Type = textTypes["G"].TextDescription,
                        Notes = goodsServices1.Text,
                        Language = (string)null
                    },
                    Row2 = new
                    {
                        Type = textTypes["G"].TextDescription,
                        Notes = goodsServices2.Text,
                        Language = (string)null
                    },
                    Row3 = new
                    {
                        Type = textTypes["G"].TextDescription,
                        Notes = goodsServices3.Text,
                        Language = 4704
                    },
                    Row4 = new
                    {
                        Type = textTypes["G"].TextDescription,
                        Notes = goodsServices4.Text,
                        Language = 4707
                    }
                }
            };
        }

        dynamic FileConventionClaimSetup(Case currentCase, Case otherCase)
        {
            var conventionClaimFromRelation = DbContext.Set<CaseRelation>().Single(_ => _.Relationship == "BAS");
            var foreignConventionFilingRelation = DbContext.Set<CaseRelation>().Single(_ => _.Relationship == "FCF");

            var bas = Insert(new RelatedCase(currentCase.Id, currentCase.CountryId, Fixture.AlphaNumericString(20), conventionClaimFromRelation, otherCase.Id)
            {
                RelatedCaseId = otherCase.Id,
                RelationshipNo = 20
            });

            var fcf = Insert(new RelatedCase(otherCase.Id, currentCase.CountryId, Fixture.AlphaNumericString(20), foreignConventionFilingRelation, currentCase.Id)
            {
                RelatedCaseId = currentCase.Id,
                RelationshipNo = 20
            });

            Insert(new FileCase
            {
                CaseId = otherCase.Id,
                IpType = "TRADEMARK_DIRECT"
            });

            Insert(new FileCase
            {
                CaseId = currentCase.Id,
                IpType = "TRADEMARK_DIRECT",
                CountryCode = currentCase.CountryId,
                ParentCaseId = otherCase.Id
            });

            return new
            {
                BAS = new
                {
                    Relationship = conventionClaimFromRelation.Description,
                    CaseRef = otherCase.Irn,
                    bas.OfficialNumber,
                    Jurisdiction = bas.CountryCode
                },
                FCF = new
                {
                    Relationship = foreignConventionFilingRelation.Description,
                    CaseRef = currentCase.Irn,
                    fcf.OfficialNumber,
                    Jurisdiction = fcf.CountryCode
                }
            };
        }
        dynamic RelatedCasesSetup(Case currentCase, Case other)
        {
            var priority = DbContext.Set<CaseRelation>().Single(_ => _.Relationship == "BAS").Description;

            var ev1 = new EventBuilder(DbContext).Create();
            var ev2 = new EventBuilder(DbContext).Create();

            var pointToParentRelation = InsertWithNewAlphaNumericId(new CaseRelation
            {
                FromEvent = ev1,
                ShowFlag = 1,
                PointsToParent = 1,
                Description = Fixture.String(20)
            });

            var pointToChildRelation = InsertWithNewAlphaNumericId(new CaseRelation
            {
                FromEvent = ev2,
                ShowFlag = 1,
                Description = Fixture.String(20)
            });

            var reciprocalRelationship = InsertWithNewAlphaNumericId(new CaseRelation
            {
                PointsToParent = 1,
                Description = Fixture.String(20)
            });

            DbContext.SaveChanges();

            var otherCase1 = new CaseBuilder(DbContext).Create(CasePrefix + "OT1", true);
            var otherCase2 = new CaseBuilder(DbContext).Create(CasePrefix + "OT2", true);

            otherCase1.LocalClasses = Fixture.String(15);
            otherCase2.LocalClasses = Fixture.String(15);

            DbContext.SaveChanges();

            var c2Jurisdiction = DbContext.Set<Country>().Single(_ => _.Id == "AU");

            // Build reciprocal relationship to an internal case - this is to derive 'pointer to child'
            Insert(new ValidRelationship(otherCase2.Country, otherCase2.PropertyType, pointToChildRelation, reciprocalRelationship));

            // Build reciprocal relationship to an external case, based on current case property type  - this is to derive 'pointer to child'
            Insert(new ValidRelationship(c2Jurisdiction, currentCase.PropertyType, pointToChildRelation, reciprocalRelationship));

            var p1 = Insert(new RelatedCase(currentCase.Id, pointToParentRelation.Relationship)
            {
                RelatedCaseId = otherCase1.Id,
                RelationshipNo = 2
            });

            var c1 = Insert(new RelatedCase(currentCase.Id, pointToChildRelation.Relationship)
            {
                RelatedCaseId = otherCase2.Id,
                RelationshipNo = 3
            });

            var c2 = Insert(new RelatedCase(currentCase.Id, "AU", Fixture.String(35), pointToChildRelation)
            {
                RelationshipNo = 4,
                PriorityDate = DateTime.Today.AddYears(-1),
                Class = Fixture.String(20),
                Cycle = Fixture.Short(),
                Title = Fixture.String(30)
            });

            var p4 = Insert(new RelatedCase(currentCase.Id, pointToParentRelation.Relationship)
            {
                RelatedCaseId = other.Id,
                RelationshipNo = 5
            });

            DbContext.SaveChanges();

            var p1c1 = Insert(new CaseEvent(otherCase1.Id, ev1.Id, 1)
            {
                EventDate = DateTime.Today,
                IsOccurredFlag = 1
            });

            var c1c1 = Insert(new CaseEvent(otherCase2.Id, ev2.Id, 1)
            {
                EventDate = DateTime.Today,
                IsOccurredFlag = 1
            });

            var p1c2 = Insert(new CaseEvent(other.Id, ev1.Id, 1)
            {
                EventDate = DateTime.Today.AddYears(-3),
                IsOccurredFlag = 1
            });

            DbContext.SaveChanges();

            return new
            {
                Priority = priority,
                P1 = new
                {
                    /* points to parent */
                    /* no specific set up for external user. */
                    Relationship = pointToParentRelation.Description,
                    CaseRef = otherCase1.Irn,
                    OfficialNumber = string.Empty,
                    Jurisdiction = otherCase1.Country.Name,
                    Date = ((DateTime)p1c1.EventDate).ToString("dd-MMM-yyyy"),
                    EventDescription = p1c1.Event.Description,
                    Classes = otherCase1.LocalClasses
                },
                C1 = new
                {
                    /* points to child */
                    /* this will be available to the external user, because it is an external case */
                    Relationship = pointToChildRelation.Description,
                    CaseRef = otherCase2.Irn,
                    OfficialNumber = string.Empty,
                    Jurisdiction = otherCase2.Country.Name,
                    Date = ((DateTime)c1c1.EventDate).ToString("dd-MMM-yyyy"),
                    EventDescription = c1c1.Event.Description,
                    Classes = otherCase2.LocalClasses
                },
                C2 = new
                {
                    /* points to child */
                    /* no specific set up for external user. */
                    Relationship = pointToChildRelation.Description,
                    CaseRef = string.Empty,
                    c2.OfficialNumber,
                    Jurisdiction = c2Jurisdiction.Name,
                    Date = ((DateTime)c2.PriorityDate).ToString("dd-MMM-yyyy"),
                    Classes = c2.Class,
                    Cycle = (short)c2.Cycle,
                    c2.Title
                },
                P2 = new
                {
                    /* points to parent */
                    /* this will be available to the external user, because the 'other' case would've been set up to be accessible by the external user */
                    Relationship = pointToParentRelation.Description,
                    CaseRef = other.Irn,
                    OfficialNumber = string.Empty,
                    Jurisdiction = other.Country.Name,
                    Date = ((DateTime)p1c2.EventDate).ToString("dd-MMM-yyyy"),
                    EventDescription = p1c2.Event.Description,
                    Classes = string.Empty
                }
            };
        }

        dynamic DesignatedJurisdictionSetup(Case currentCase, bool isExternal)
        {
            var cf1 = Insert(new CountryFlag(currentCase.CountryId, Fixture.Integer(), Fixture.AlphaNumericString(5)));
            var cf2 = Insert(new CountryFlag(currentCase.CountryId, Fixture.Integer(), Fixture.AlphaNumericString(5)));

            var clientReference = Fixture.AlphaNumericString(5);
            var country1 = Insert(new Country
            {
                Id = "AZZ",
                Name = Fixture.Prefix("A"),
                Type = "0"
            });

            var designationCase1 = new CaseBuilder(DbContext).Create(CasePrefix + "designation1", true, country: country1);
            designationCase1.Title = Fixture.AlphaNumericString(5);
            designationCase1.PropertyType = DbContext.Set<PropertyType>().Single(vq => vq.Code == KnownPropertyTypes.Patent);
            designationCase1.CaseStatus = DbContext.Set<Status>().Add(new Status(Fixture.Short(), Fixture.AlphaNumericString(5)) { RegisteredFlag = 0m, LiveFlag = 0m }); /* Dead status */

            var forbiddenNameType = DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Owner);
            var clientNameTypes = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.ClientNameTypesShown).StringValue.Split(',');
            var withoutOwnerNameTypes = clientNameTypes.Where(cnt => cnt != forbiddenNameType.NameTypeCode).ToArray();
            DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.ClientNameTypesShown).StringValue = string.Join(",", withoutOwnerNameTypes);
            DbContext.SaveChanges();

            designationCase1.CaseNames.First(_ => _.NameTypeId == KnownNameTypes.Instructor).Reference = clientReference;

            Insert(new FileCase
            {
                CaseId = currentCase.Id,
                IpType = "PATENT_POST_PCT"
            });

            Insert(new FileCase
            {
                CaseId = designationCase1.Id,
                ParentCaseId = currentCase.Id,
                IpType = "PATENT_POST_PCT",
                CountryCode = designationCase1.CountryId
            });

            var classText1 = Fixture.String(5).Replace(",", string.Empty);
            var classText2 = Fixture.String(5).Replace(",", string.Empty);
            var classText3 = Fixture.String(5).Replace(",", string.Empty);
            designationCase1.LocalClasses = $"{classText1},{classText2},{classText3}";

            DbContext.SaveChanges();

            var caseTexts = DbContext.Set<CaseText>().Where(_ => _.CaseId == designationCase1.Id && _.Type == KnownTextTypes.GoodsServices).ToArray();
            var firstLanguage = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.Language);
            var secondLanguage = DbContext.Set<TableCode>().Where(_ => _.TableTypeId == (int)TableTypes.Language && _.UserCode != null).OrderByDescending(_ => _.Id).First();

            caseTexts.First().Language = firstLanguage.Id;
            caseTexts.Last().Language = secondLanguage.Id;
            caseTexts.First().ShortText = Fixture.String(15);
            caseTexts.Last().ShortText = Fixture.String(15);

            var criticalDatesSiteControl = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.LANGUAGE);
            criticalDatesSiteControl.IntegerValue = secondLanguage.Id;
            Insert(new CountryGroup(currentCase.Country, country1) { AssociateMember = 1 });

            var relatedCase1 = Insert(new RelatedCase(currentCase.Id, KnownRelations.DesignatedCountry1, designationCase1.CountryId)
            {
                RelationshipNo = 11,
                PriorityDate = DateTime.Today.AddYears(-1),
                Class = Fixture.String(20),
                Cycle = Fixture.Short(),
                Title = Fixture.String(30),
                CurrentStatus = cf1.FlagNumber,
                RelatedCaseId = designationCase1.Id,
                Notes = Fixture.String(20)
            });

            var country2 = Insert(new Country
            {
                Id = "BZZ",
                Name = Fixture.Prefix("B"),
                Type = "0"
            });
            var designationCase2 = new CaseBuilder(DbContext).Create(CasePrefix + "designation2", true, country: country2);
            designationCase2.Title = Fixture.AlphaNumericString(5);
            designationCase2.PropertyType = DbContext.Set<PropertyType>().Single(vq => vq.Code == KnownPropertyTypes.Patent);
            designationCase2.CaseStatus = DbContext.Set<Status>().Add(new Status(Fixture.Short(), Fixture.AlphaNumericString(5)) { RegisteredFlag = 1, LiveFlag = 1 });
            Insert(new CountryGroup(currentCase.Country, country2));

            var relatedCase2 = Insert(new RelatedCase(currentCase.Id, KnownRelations.DesignatedCountry1, designationCase2.CountryId)
            {
                RelationshipNo = 12,
                PriorityDate = DateTime.Today,
                Class = Fixture.String(20),
                CurrentStatus = cf2.FlagNumber,
                RelatedCaseId = designationCase2.Id,
                Notes = Fixture.String(10)
            });

            var action = DbContext.Set<Action>().First(_ => _.Name == CriticialDateActionName);
            var criteria = DbContext.Set<Criteria>().First(_ => _.CaseTypeId == "A" && _.PurposeCode == CriteriaPurposeCodes.EventsAndEntries && _.RuleInUse == 1 && _.ActionId == action.Code);
            var critcalDates = DbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteria.Id);

            return new
            {
                RegisterForAccess = designationCase1,
                Row1 = new
                {
                    Case = new DesignatedJurisdictionData
                    {
                        Jurisdiction = designationCase1.Country.Name,
                        DesignatedStatus = cf1.Name,
                        CaseStatus = isExternal ? KnownStatusCodes.Dead.ToString() : designationCase1.CaseStatus.Name,
                        ClientReference = clientReference,
                        InternalReference = designationCase1.Irn,
                        Classes = designationCase1.LocalClasses,
                        Notes = relatedCase1.Notes
                    },
                    Details = new OverviewSummary
                    {
                        PropertyType = designationCase1.PropertyType?.Name,
                        CaseCategory = designationCase1.Category?.Name,
                        Title = designationCase1.Title,
                        Names = designationCase1.CaseNames.Where(cn => cn.NameTypeId != forbiddenNameType.NameTypeCode || !isExternal).Select(_ => new NameSummary
                        {
                            NameType = _.NameType.Name,
                            N = _.Name
                        }).ToArray(),
                        CriticalDates = critcalDates.Select(_ => new CriticalDate
                        {
                            EventDefinition = _.Description
                        }).ToArray()
                    },
                    ClasssData = new List<CaseTextData>
                    {
                        new CaseTextData {TextClass = classText1, Language = firstLanguage.Name, Notes = caseTexts.First().ShortText},
                        new CaseTextData {TextClass = classText2},
                        new CaseTextData {TextClass = classText3, Language = secondLanguage.Name, Notes = caseTexts.Last().ShortText}
                    }.OrderBy(_ => _.TextClass).ThenBy(_ => _.Language).ToList()
                },
                Row2 = new
                {
                    Case = new DesignatedJurisdictionData
                    {
                        Jurisdiction = designationCase2.Country.Name,
                        DesignatedStatus = cf2.Name,
                        CaseStatus = isExternal ? KnownStatusCodes.Registered.ToString() : designationCase2.CaseStatus.Name,
                        ClientReference = string.Empty,
                        InternalReference = designationCase2.Irn,
                        Classes = designationCase2.LocalClasses,
                        Notes = relatedCase2.Notes
                    },
                    Details = new OverviewSummary
                    {
                        PropertyType = designationCase2.PropertyType?.Name,
                        CaseCategory = designationCase2.Category?.Name,
                        Title = designationCase2.Title,
                        Names = designationCase2.CaseNames.Where(cn => cn.NameTypeId != forbiddenNameType.NameTypeCode || !isExternal).Select(_ => new NameSummary
                        {
                            NameType = _.NameType.Name,
                            N = _.Name
                        }).ToArray(),
                        CriticalDates = critcalDates.Select(_ => new CriticalDate
                        {
                            EventDefinition = _.Description
                        }).ToArray()
                    },
                    ClasssData = new List<CaseTextData>()
                }
            };
        }

        public Dictionary<Case, dynamic> CriticalDatesAndEventsSetup(params Case[] cases)
        {
            var today = DateTime.Today;

            var importanceLevel = Insert(new Importance("6", Fixture.Prefix(Fixture.String(3))));
            var importanceLevel2 = DbContext.Set<Importance>().Single(i => i.Level == "9");

            var criticalDateAction = InsertWithNewId(new Action(CriticialDateActionName), x => x.Code);
            var criticalDateCriteria = new CriteriaBuilder(DbContext).Create();

            criticalDateCriteria.RuleInUse = 1;
            criticalDateCriteria.CaseTypeId = "A";
            criticalDateCriteria.Action = criticalDateAction;

            var criticalDatesSiteControl = DbContext.Set<SiteControl>().Single(_ => _.ControlId == CriticalDatesSiteControlId);
            criticalDatesSiteControl.StringValue = criticalDateAction.Code;

            DbContext.SaveChanges();

            // CriticalDates Setup
            // set up priority details

            var priorityEvent = DbContext.Set<Event>().Single(_ => _.Id == (int)KnownEvents.EarliestPriority);

            var priorityValidEvent = new ValidEventBuilder(DbContext).Create(criticalDateCriteria, priorityEvent, importance: importanceLevel);
            priorityValidEvent.Event.ImportanceLevel = "9";
            priorityValidEvent.DisplaySequence = 1;

            var d = (from cr in DbContext.Set<CaseRelation>()
                     join sc in DbContext.Set<SiteControl>() on cr.Relationship equals sc.StringValue into sc1
                     from sc in sc1
                     join j in DbContext.Set<Country>() on "CA" equals j.Id into j1
                     from j in j1
                     where sc.ControlId == SiteControls.EarliestPriority
                     select new
                     {
                         PriorityRelationship = cr,
                         Jurisdiction = j.Name
                     }).Single();

            // Set up occurred events that appear in the Events grid - the below should show the first one.

            var anotherAction = InsertWithNewId(new Action(CasePrefix + "-AC"), x => x.Code);

            var anotherCriteria = new CriteriaBuilder(DbContext).Create();

            anotherCriteria.RuleInUse = 1;
            anotherCriteria.CaseTypeId = "A";
            anotherCriteria.Action = anotherAction;

            var @event = new EventBuilder(DbContext).Create();

            /* both the critical date criteria and another criteria (for each case) refers to this event */

            var anotherCriteriaValidEvent = new ValidEventBuilder(DbContext).Create(criticalDateCriteria, @event, importance: importanceLevel);
            anotherCriteriaValidEvent.Event.ImportanceLevel = "6";
            anotherCriteriaValidEvent.Description = Fixture.Prefix("CriticalDatesEvents");
            anotherCriteriaValidEvent.DisplaySequence = 2;

            var validEvent1 = new ValidEventBuilder(DbContext).Create(anotherCriteria, @event, importance: importanceLevel);
            validEvent1.Description = Fixture.Prefix("OpenActionEvent");

            @event.ControllingAction = anotherAction.Code;

            var eventFromCase = new CaseBuilder(DbContext).Create(CasePrefix + "M", true);

            var result = new Dictionary<Case, dynamic>();

            foreach (var @case in cases)
            {
                var priorityNumber = Fixture.String(20);

                var priorityCase = Insert(new RelatedCase(@case.Id, "CA", priorityNumber, d.PriorityRelationship) { RelationshipNo = 1 });
                priorityCase.PriorityDate = today;

                Insert(new CaseEvent(@case.Id, priorityEvent.Id, 1)
                {
                    EventDate = priorityCase.PriorityDate,
                    IsOccurredFlag = 1
                });

                DbContext.SaveChanges();

                // this event is picked up by Events because the event has a controlling action that is opened in the case
                // this event will also be picked up as last event in Critical Dates, because the critical dates criteria refers to this event

                var staff = @case.CaseNames.First(_ => _.NameTypeId == KnownNameTypes.StaffMember).Name;

                Insert(new CaseEvent(@case.Id, @event.Id, 1)
                {
                    EventDate = today.AddDays(-5),
                    EventDueDate = today.AddDays(3),
                    IsOccurredFlag = 1,
                    EmployeeNo = staff.Id,
                    DueDateResponsibilityNameType = "A",
                    FromCaseId = eventFromCase.Id
                });

                DbContext.SaveChanges();

                // Set up occurred events that appear in the Events grid - the below should show the second and third

                Insert(new OpenAction(anotherAction, @case, 1, null, anotherCriteria, true));

                var otherAction = InsertWithNewId(new Action(CasePrefix + "-OA")
                {
                    NumberOfCyclesAllowed = 2
                }, x => x.Code);

                var otherCriteria = new CriteriaBuilder(DbContext).Create();

                otherCriteria.RuleInUse = 1;
                otherCriteria.CaseTypeId = "A";
                otherCriteria.Action = otherAction;

                var otherValidEvent = new ValidEventBuilder(DbContext).Create(otherCriteria, importance: importanceLevel2);
                otherValidEvent.Event.ImportanceLevel = "6";
                otherValidEvent.DisplaySequence = 1;

                // Closed Action Event (cycle:1) - should be pick up by Events eventhough the action is closed

                Insert(new OpenAction(otherAction, @case, 1, null, otherCriteria, false));

                Insert(new CaseEvent(@case.Id, otherValidEvent.EventId, 1)
                {
                    EventDate = today.AddYears(-2),
                    IsOccurredFlag = 1,
                    CreatedByCriteriaKey = otherCriteria.Id,
                    CreatedByActionKey = otherAction.Code
                });

                // Open Action Event (cycle:2) - should be pick up by Events

                Insert(new OpenAction(otherAction, @case, 2, null, otherCriteria, true));

                Insert(new CaseEvent(@case.Id, otherValidEvent.EventId, 2)
                {
                    EventDate = today.AddYears(-1),
                    IsOccurredFlag = 1,
                    CreatedByCriteriaKey = otherCriteria.Id,
                    CreatedByActionKey = otherAction.Code
                });

                DbContext.SaveChanges();

                // Caseview Due Events
                var dueAction = InsertWithNewId(new Action(CasePrefix + "-Due"), x => x.Code);
                var dueCriteria = new CriteriaBuilder(DbContext).Create();

                dueCriteria.RuleInUse = 1;
                dueCriteria.CaseTypeId = "A";
                dueCriteria.Action = dueAction;

                var dueValidEvent = new ValidEventBuilder(DbContext).Create(dueCriteria, importance: importanceLevel);
                dueValidEvent.Event.ImportanceLevel = "6";
                dueValidEvent.DisplaySequence = 4;

                DbContext.SaveChanges();

                Insert(new OpenAction(dueAction, @case, 1, null, dueCriteria, true));

                dueValidEvent.Event.ControllingAction = dueAction.Code;

                Insert(new CaseEvent(@case.Id, dueValidEvent.EventId, 1)
                {
                    EventDueDate = today.AddYears(-2),
                    IsOccurredFlag = 0,
                    CreatedByCriteriaKey = dueCriteria.Id,
                    CreatedByActionKey = dueAction.Code
                });

                var dueValidEvent2 = new ValidEventBuilder(DbContext).Create(dueCriteria, importance: importanceLevel);
                dueValidEvent2.Event.ImportanceLevel = "6";
                dueValidEvent2.DisplaySequence = 2;
                Insert(new CaseEvent(@case.Id, dueValidEvent2.EventId, 1)
                {
                    EventDueDate = today,
                    IsOccurredFlag = 0,
                    CreatedByCriteriaKey = dueCriteria.Id,
                    CreatedByActionKey = dueAction.Code
                });

                var dueValidEvent3 = new ValidEventBuilder(DbContext).Create(dueCriteria, importance: importanceLevel);
                dueValidEvent3.Event.ImportanceLevel = "6";
                dueValidEvent3.DisplaySequence = 2;

                Insert(new CaseEvent(@case.Id, dueValidEvent3.EventId, 1)
                {
                    EventDueDate = today.AddDays(5),
                    IsOccurredFlag = 0,
                    CreatedByCriteriaKey = dueCriteria.Id,
                    CreatedByActionKey = dueAction.Code,
                    EmployeeNo = staff.Id,
                    FromCaseId = eventFromCase.Id
                });

                DbContext.SaveChanges();

                result.Add(@case, new
                {
                    CriticalDates = new
                    {
                        Row1 = new
                        {
                            /* available to external user, because event client importance level == 9 see fn_FilterUserEvents */
                            EventDescription = priorityValidEvent.Description,
                            PriorityNumber = priorityNumber,
                            PriorityCountry = d.Jurisdiction,
                            PriorityDate = priorityCase.PriorityDate.Value.ToString("dd-MMM-yyyy")
                        },
                        Row2 = new
                        {
                            /* not available to external user because event client importance level < 9 see fn_FilterUserEvents */
                            EventDescription = anotherCriteriaValidEvent.Description,
                            EventDate = today.AddDays(-5).ToString("dd-MMM-yyyy")
                        },
                        Row3 = new
                        {
                            /* not available to external user because event client importance level < 9 see fn_FilterUserEvents */
                            EventDescription = dueValidEvent.Description,
                            EventDate = today.AddYears(-2).ToString("dd-MMM-yyyy")
                        },
                        Row4 = new
                        {
                            /* not available to external user because event client importance level < 9 see fn_FilterUserEvents */
                            EventDescription = otherValidEvent.Description,
                            EventDate = today.AddYears(-1).ToString("dd-MMM-yyyy")
                        }
                    },
                    Events = new
                    {
                        Row1 = new
                        {
                            EventDescription = validEvent1.Description,
                            EventDate = today.AddDays(-5).ToString("dd-MMM-yyyy")
                        },
                        Row2 = new
                        {
                            EventDescription = otherValidEvent.Description,
                            EventDate = today.AddYears(-1).ToString("dd-MMM-yyyy")
                        },
                        Row3 = new
                        {
                            EventDescription = otherValidEvent.Description,
                            EventDate = today.AddYears(-2).ToString("dd-MMM-yyyy"),
                            EmployeeNo = staff.Id,
                            FromCaseId = eventFromCase.Id,
                            ResponseFirstName = staff.FirstName,
                            FromCaseIrn = eventFromCase.Irn
                        }
                    },
                    EventsDue = new
                    {
                        Row1 = new
                        {
                            EventDescription = dueValidEvent.Description,
                            EventDate = today.AddYears(-2).ToString("dd-MMM-yyyy")
                        },
                        Row2 = new
                        {
                            EventDescription = dueValidEvent2.Description,
                            EventDate = today.ToString("dd-MMM-yyyy")
                        },
                        Row3 = new
                        {
                            EventDescription = dueValidEvent3.Description,
                            EventDate = today.AddDays(5).ToString("dd-MMM-yyyy"),
                            EmployeeNo = staff.Id,
                            ResponseFirstName = staff.FirstName,
                            FromCaseId = eventFromCase.Id,
                            FromCaseIrn = eventFromCase.Irn
                        }
                    }
                });
            }

            return result;
        }

        public (OfficialNumber ipOfficeNumber, OfficialNumber otherNumber) OfficialNumbers(Case @case)
        {
            var numberType = DbContext.Set<NumberType>().Single(_ => _.NumberTypeCode == KnownNumberTypes.Application);
            var ipOffice = Insert(new OfficialNumber(numberType, @case, Fixture.Prefix("IpOffice"))
            {
                IsCurrent = 1
            });
            var numberTypeIpOffice = InsertWithNewId(new NumberType { Name = Fixture.Prefix() }, x => x.NumberTypeCode);
            var other = Insert(new OfficialNumber(numberTypeIpOffice, @case, Fixture.Prefix("other"))
            {
                IsCurrent = 1
            });

            return (ipOffice, other);
        }

        public IEnumerable<Criteria> CaseWebLinks(Case @case)
        {
            var officeId = @case.Office?.Id;
            var countryId = @case.Country?.Id;
            var caseCategoryId = @case.Category?.CaseCategoryId;
            var subTypeId = @case.SubType?.Code;
            var basis = @case.Property?.Basis;
            return DbContext.Set<Criteria>().Where(_ => _.PurposeCode == CriteriaPurposeCodes.CaseLinks && _.RuleInUse == 1
                                                                                                        && (_.OfficeId == null || _.OfficeId == officeId)
                                                                                                        && (_.CaseTypeId == null || _.CaseTypeId == @case.TypeId)
                                                                                                        && (_.PropertyTypeId == null || _.PropertyTypeId == @case.PropertyTypeId)
                                                                                                        && (_.CountryId == null || _.CountryId == countryId)
                                                                                                        && (_.CaseCategoryId == null || _.CaseCategoryId == caseCategoryId)
                                                                                                        && (_.SubTypeId == null || _.SubTypeId == subTypeId)
                                                                                                        && (_.BasisId == null || _.BasisId == basis));
        }

        public dynamic SetupDesignElementAndCaseImage(Case @case)
        {
            var designElement1 = Insert(new DesignElement(@case.Id, Fixture.Integer())
            {
                ClientElementId = Fixture.String(5),
                Description = Fixture.String(5),
                FirmElementId = "123-456",
                IsRenew = true,
            });

            var designElement2 = Insert(new DesignElement(@case.Id, Fixture.Integer())
            {
                ClientElementId = Fixture.String(5),
                Description = Fixture.String(5),
                FirmElementId = "456-476",
                IsRenew = true
            });

            var imageStatus = DbContext.Set<TableCode>().Single(_ => _.TableTypeId == (short)TableTypes.ImageStatus && _.Id == ProtectedTableCode.PropertyTypeImageStatus);
            var imageType = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.ImageTypeForCaseHeader).IntegerValue;
            var png1 = Fixture.Image(500, 500, Color.Black);
            var image1 = InsertWithNewId(new Image { ImageData = png1 });

            var imageDetail = Insert(new ImageDetail(image1.Id)
            {
                ImageDescription = "E2E" + Fixture.String(5),
                ImageStatus = imageStatus.Id
            });

            Insert(new CaseImage(@case, image1.Id, 0, imageType.GetValueOrDefault(1201)) { CaseImageDescription = Fixture.String(5), FirmElementId = designElement1.FirmElementId });

            return new { designElement1, designElement2, imageDetail };
        }

        public dynamic SetupCaseFileLocations(Case @case)
        {
            var fileLocation = InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.FileLocation, Name = "Location1" });

            var filePart = InsertWithNewId(new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = "Part1" });

            var caseLocation1 = InsertWithNewId(new CaseLocation(@case, fileLocation, Fixture.PastDate()) { BayNo = "001", FilePartId = filePart.FilePart });
            @case.CaseLocations.Add(caseLocation1);

            var caseLocation2 = InsertWithNewId(new CaseLocation(@case, fileLocation, Fixture.Today().AddDays(-1)) { BayNo = "002" });
            @case.CaseLocations.Add(caseLocation2);

            var caseLocation3 = InsertWithNewId(new CaseLocation(@case, fileLocation, Fixture.Today()) { BayNo = "002" });
            @case.CaseLocations.Add(caseLocation3);

            return new { caseLocation1, caseLocation2 };
        }

        public dynamic SetupKeepOnTopNotesFor16(Case @case)
        {
            var tt1 = Insert(new TextType { Id = "TT", TextDescription = "E2E Test CaseView" });

            var kot1 = InsertWithNewId(new KeepOnTopTextType { TextTypeId = tt1?.Id, TextType = tt1, CaseProgram = true, NameProgram = false, TimeProgram = false, IsRegistered = false, IsPending = false, IsDead = false, Type = KnownKotTypes.Case, BackgroundColor = "#b9d87b" });
            var kotCt1 = Insert(new KeepOnTopCaseType { CaseTypeId = @case.Type.Code, CaseType = @case.Type, KotTextTypeId = kot1.Id, KotTextType = kot1 });

            kot1.KotCaseTypes = new List<KeepOnTopCaseType>()
            {
                kotCt1
            };

            @case.CaseStatus = DbContext.Set<Status>().FirstOrDefault(x => x.Id == -291);
            var caseText1 = Insert(new CaseText(@case.Id, tt1.Id, 0, null)
            {
                Language = null,
                Text = "First",
                TextType = tt1
            });

            var IeColor = "rgba(185, 216, 123, 1)";
            var OtherBrowserColor = "rgb(185, 216, 123)";

            return new { tt1, kot1, @case, caseText1, IeColor, OtherBrowserColor };
        }

        public dynamic SetupKeepOnTopNotesFor13(Case @case)
        {
            var tt1 = DbContext.Set<TextType>().FirstOrDefault(x => x.Id == "A");
            @case.Type.TextType = tt1;
            @case.Type.KotTextType = tt1?.Id;
            @case.Type.Program = 1;
            var caseText1 = Insert(new CaseText(@case.Id, @case.Type.Code, 0, null)
            {
                Language = null,
                Text = "First KOT Test",
                TextType = tt1,
                LongText = "First KOT long test E2e",
                IsLongText = 1
            });
            return new { @case, caseText1 };
        }

        public void SetupDesignElementForPaging(Case @case)
        {
            SetupDesignElementAndCaseImage(@case);
            Insert(new DesignElement(@case.Id, Fixture.Integer())
            {
                ClientElementId = Fixture.String(5),
                Description = Fixture.String(5),
                FirmElementId = "e2e" + Fixture.String(5),
                IsRenew = true,
            });

            Insert(new DesignElement(@case.Id, Fixture.Integer())
            {
                ClientElementId = Fixture.String(5),
                Description = Fixture.String(5),
                FirmElementId = "e2e" + Fixture.String(5),
                IsRenew = true,
            });

            Insert(new DesignElement(@case.Id, Fixture.Integer())
            {
                ClientElementId = Fixture.String(5),
                Description = Fixture.String(5),
                FirmElementId = "e2e" + Fixture.String(5),
                IsRenew = true,
            });

            Insert(new DesignElement(@case.Id, Fixture.Integer())
            {
                ClientElementId = Fixture.String(5),
                Description = Fixture.String(5),
                FirmElementId = "e2e" + Fixture.String(5),
                IsRenew = true,
            });
        }
        public IEnumerable<dynamic> SetupRenewalDetailsAndEvents(Case @case)
        {
            var knownRenewalType = DbContext.Set<TableCode>().Where(_ => _.TableTypeId == (int)TableTypes.RenewalType).OrderBy(_ => _.Id).First();
            var applicationBasis = DbContext.Set<ApplicationBasis>().Single(_ => _.Code == "N");
            var rewnalStatus = DbContext.Set<Status>().Where(_ => _.RenewalFlag == 1).OrderBy(_ => _.Id).First();
            @case.Property = new CaseProperty(@case, applicationBasis, rewnalStatus) { RenewalType = knownRenewalType.Id, RenewalNotes = "Test Notes" };
            @case.ExtendedRenewals = 10;

            @case.ReportToThirdParty = 1;

            var renewalDisplayAction = InsertWithNewId(new Action(RenewalDisplayActionName), x => x.Code);
            var renewalDisplayCriteria = new CriteriaBuilder(DbContext).Create();

            renewalDisplayCriteria.RuleInUse = 1;
            renewalDisplayCriteria.CaseTypeId = "A";
            renewalDisplayCriteria.Action = renewalDisplayAction;

            var renewalRelevantDatesSiteControl = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.RenewalDisplayActionCode);
            renewalRelevantDatesSiteControl.StringValue = renewalDisplayAction.Code;

            dynamic AddCaseEvent(DateTime date, string eventText, short displaySeq)
            {
                var validEvent = new ValidEventBuilder(DbContext).Create(renewalDisplayCriteria, null, eventText);
                validEvent.Event.ImportanceLevel = "9";
                validEvent.DisplaySequence = displaySeq;

                Insert(new CaseEvent(@case.Id, validEvent.EventId, 1)
                {
                    EventDate = date < DateTime.Today ? date : (DateTime?)null,
                    EventDueDate = date > DateTime.Today ? date : (DateTime?)null
                });

                return new { date, eventText };
            }

            yield return AddCaseEvent(DateTime.Today.AddYears(2), Fixture.String(60), 1);
            yield return AddCaseEvent(DateTime.Today.AddYears(-2), Fixture.String(60), 2);
        }

        public dynamic SetupRenewalStandingInstructions()
        {
            var name = new NameBuilder(DbContext).CreateOrg(0, "renew");
            var homeNamenoSiteControl = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.HomeNameNo);
            homeNamenoSiteControl.IntegerValue = name.Id;

            var instructionType = DbContext.Set<InstructionType>().Include(_ => _.NameType).Single(_ => _.Code == RenewalInstructionTypeCode);
            var instruction = InsertWithNewId(new Instruction { InstructionType = instructionType, Description = Fixture.String(20) });
            Insert(new NameInstruction { InstructionId = instruction.Id, Id = name.Id, Sequence = 0 });

            return new
            {
                InstructionTypeDescription = instruction.InstructionType.Description,
                Instruction = instruction.Description,
                DefaultedFrom = name.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName)
            };
        }

        public string SetupRenewLinkData(Case @case)
        {
            const string ipPlatformRenewLink = "renewals/#/renewals/cases/v1/IPRURN/";
            var iprurn = Fixture.Short(9000).ToString();

            InsertWithNewId(new CpaPortfolio(@case, DateTime.Now, "L") { ResponsibleParty = "C", IprUrn = iprurn });
            @case.ReportToThirdParty = 1m;

            var renewalRelevantDatesSiteControl = DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.CPA_UseClientCaseCode);
            renewalRelevantDatesSiteControl.BooleanValue = true;

            return ipPlatformRenewLink + iprurn;
        }

        public dynamic SetupStandingInstructions(Case @case)
        {
            var caseName = @case.CaseNames.FirstOrDefault();
            if (caseName == null)
                return null;

            var instructionType = DbContext.Set<InstructionType>().Include(_ => _.NameType).Single(_ => _.Code == ExaminationInstructionTypeCode);
            var instruction = InsertWithNewId(new Instruction { InstructionType = instructionType, Description = Fixture.String(20) });

            var text = Fixture.String(20);
            Insert(new NameInstruction
            {
                InstructionId = instruction.Id,
                Id = caseName.NameId,
                Sequence = 1,
                Period1Amt = 1,
                Period1Type = "D",
                Period2Amt = 2,
                Period2Type = "W",
                Adjustment = KnownAdjustment.HalfYearly,
                AdjustStartMonth = 1,
                AdjustDay = 15,
                StandingInstructionText = text
            });

            return new
            {
                InstructionTypeDescription = instructionType.Description,
                Instruction = instruction.Description,
                DefaultedFrom = caseName.Name.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName),
                Period1 = "1 Days",
                Period2 = "2 Weeks",
                Period3 = string.Empty,
                Adjustment = "Half-yearly",
                AdjustStartMonth = "July",
                AdjustDay = 15.ToString(),
                Text = text
            };
        }

        public dynamic SetupChecklists(Case @case)
        {
            var checklist = InsertWithNewId(new CheckList { Description = Fixture.Prefix("e2e case checklist") });

            var validChecklist = Insert(new ValidChecklist(@case.Country, @case.PropertyType, @case.Type, checklist)
            {
                ChecklistDescription = Fixture.Prefix("e2e valid case checklist")
            });
            var checklistEvent = new EventBuilder(DbContext).Create();
            var checklistCaseEvent = Insert(new CaseEvent(@case.Id, checklistEvent.Id, 1)
            {
                EventDate = DateTime.Today.AddYears(-2),
                EnteredDeadline = 5,
                IsOccurredFlag = 1
            });
            var checklistCriteria = new CriteriaBuilder(DbContext).Create();
            checklistCriteria.PurposeCode = CriteriaPurposeCodes.CheckList;
            checklistCriteria.ChecklistType = checklist.Id;
            checklistCriteria.RuleInUse = 1;
            checklistCriteria.Country = @case.Country;
            checklistCriteria.CaseType = @case.Type;
            checklistCriteria.Office = @case.Office;
            checklistCriteria.PropertyType = @case.PropertyType;

            var question = InsertWithNewId(new Question { QuestionString = "e2e question 01" });
            var question2 = InsertWithNewId(new Question { QuestionString = "e2e question 02", YesNoRequired = 4 });
            var question3 = InsertWithNewId(new Question { QuestionString = "e2e question 03" });
            var charge = InsertWithNewId(new ChargeType { Description = Fixture.Prefix("chargeType") });
            Insert(new Rates { Id = charge.Id, RateDescription = Fixture.Prefix("rate") });
            var checklistItemQuestion = Insert(new ChecklistItem { Criteria = checklistCriteria, Question = "e2e checklist item question 01", QuestionId = question.Id, SequenceNo = 0, YesAnsweredEventId = checklistEvent.Id, YesNoRequired = 1, CountRequired = 1, TextRequired = 1 });
            var checklistItemQuestion2 = Insert(new ChecklistItem { Criteria = checklistCriteria, Question = "e2e checklist item question 02", QuestionId = question2.Id, SequenceNo = 0, YesNoRequired = 4, AmountRequired = 1, EmployeeRequired = 2 });
            var checklistItemQuestion3 = Insert(new ChecklistItem { Criteria = checklistCriteria, Question = "e2e checklist item question 03", QuestionId = question3.Id, SequenceNo = 0, SourceQuestion = question2.Id, AnswerSourceNo = 4, AnswerSourceYes = 5 });

            var caseChecklistItem = Insert(new CaseChecklist(validChecklist.ChecklistType, @case.Id, question.Id) { ProcessedFlag = (decimal)1.0, EmployeeId = null, CountAnswer = 5, YesNoAnswer = 1, ChecklistText = "test" });
            var caseChecklistItem2 = Insert(new CaseChecklist(validChecklist.ChecklistType, @case.Id, question2.Id) { ProcessedFlag = (decimal)0.0, EmployeeId = null, ValueAnswer = 5, YesNoAnswer = 1 });

            var letter = InsertWithNewId(new Document(Fixture.Prefix("letter"), Fixture.String(10)));
            var checklistLetter = Insert(new ChecklistLetter { CriteriaId = checklistCriteria.Id, QuestionId = question.Id, LetterNo = letter.Id });
            return new
            {
                ValidChecklist = validChecklist,
                ChecklistItemQuestion = checklistItemQuestion,
                CaseChecklist = caseChecklistItem,
                CaseChecklistEvent = checklistCaseEvent,
                ChecklistItemQuestion2 = checklistItemQuestion2,
                CaseChecklist2 = caseChecklistItem2,
                ChecklistItemQuestion3 = checklistItemQuestion3,
                ChecklistLetter = checklistLetter
            };
        }
    }
}