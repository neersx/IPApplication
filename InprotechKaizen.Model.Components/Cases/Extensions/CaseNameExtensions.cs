using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Extensions
{
    public static class CaseNameExtensions
    {
        public static DerivedContact GetDerivedContact(this CaseName caseName, IDbContext dbContext)
        {
            if(caseName == null) throw new ArgumentNullException("caseName");
            if(dbContext == null) throw new ArgumentNullException("dbContext");

            var addressCode = caseName.Address == null ? null : (int?)caseName.Address.Id;
            var attentionCode = caseName.AttentionName == null ? null : (int?)caseName.AttentionName.Id;
            var name = dbContext.Set<Name>().FirstOrDefault(cn => cn.Id == caseName.NameId);

            if(caseName.NameTypeId.Equals(KnownNameTypes.Debtor) ||
               caseName.NameTypeId.Equals(KnownNameTypes.RenewalsDebtor))
            {
                var associatedName =
                    dbContext.Set<AssociatedName>().FirstOrDefault(
                                                                   an => an.Name.Id == caseName.NameId
                                                                         &&
                                                                         an.RelatedNameId ==
                                                                         caseName.InheritedFromNameId
                                                                         &&
                                                                         an.Relationship ==
                                                                         caseName.InheritedFromRelationId
                                                                         &&
                                                                         an.Sequence == caseName.InheritedFromSequence);

                var associatedBillingName = dbContext.Set<AssociatedName>().FirstOrDefault(
                                                                                           an =>
                                                                                           an.Name.Id == caseName.NameId
                                                                                           &&
                                                                                           an.RelatedNameId ==
                                                                                           caseName.NameId
                                                                                           &&
                                                                                           an.Relationship.Equals(
                                                                                                                  KnownRelations
                                                                                                                      .SendBillsTo));

                addressCode = LinqExtensions.Coalesce(
                                                      addressCode,
                                                      associatedName == null ? null : associatedName.PostalAddressId,
                                                      associatedBillingName == null
                                                           ? null
                                                           : associatedBillingName.PostalAddressId,
                                                      name == null ? null : name.PostalAddressId);

                attentionCode = LinqExtensions.Coalesce(
                                                        attentionCode,
                                                        associatedName == null ? null : associatedName.ContactId,
                                                        associatedBillingName == null
                                                             ? null
                                                             : associatedBillingName.ContactId,
                                                        name == null ? null : name.MainContactId);
            }
            else
            {
                if(attentionCode == null)
                {
                    var mainContactAsAttn =
                        dbContext.Set<SiteControl>()
                                 .FirstOrDefault(sc => sc.ControlId == SiteControls.MainContactusedasAttention);
                    if(mainContactAsAttn != null && mainContactAsAttn.BooleanValue.GetValueOrDefault())
                        attentionCode = name == null ? null : name.MainContactId;
                }

                var bestFitAssociatedName =
                    dbContext.Set<AssociatedName>().Where(
                                                          an => an.Name.Id == caseName.NameId
                                                                && an.Relationship.Equals(KnownRelations.Employs)
                                                                &&
                                                                (an.PropertyTypeId == null || an.CountryCode == null ||
                                                                 an.RelatedNameId == name.MainContactId)
                                                                &&
                                                                (an.PropertyTypeId == caseName.Case.PropertyType.Code ||
                                                                 an.PropertyTypeId == null)
                                                                &&
                                                                (an.CountryCode == caseName.Case.Country.Id ||
                                                                 an.CountryCode == null))
                             .AsEnumerable()
                             .OrderBy(
                                      an => an.GetBestFitAssociatedName(name)).FirstOrDefault();

                var relatedNameId = bestFitAssociatedName != null ? bestFitAssociatedName.RelatedNameId : (int?)null;

                addressCode = LinqExtensions.Coalesce(
                                                      addressCode,
                                                      name == null
                                                           ? null
                                                           : (caseName.NameType.KeepStreetFlag.GetValueOrDefault() == 1)
                                                                 ? name.StreetAddressId
                                                                 : name.PostalAddressId);

                attentionCode = LinqExtensions.Coalesce(
                                                        attentionCode,
                                                        relatedNameId,
                                                        name == null ? null : name.MainContactId);
            }

            var address = dbContext.Set<Address>()
                                   .FirstOrDefault(cn => cn.Id == addressCode);

            var attention = dbContext.Set<Name>()
                                     .FirstOrDefault(cn => cn.Id == attentionCode);

            return new DerivedContact(attention, address);
        }

        public static bool HasDebtorRestrictions(this CaseName caseName, short[] restrictionAction)
        {
            if(caseName == null) throw new ArgumentNullException("caseName");
            if(restrictionAction == null) throw new ArgumentNullException("restrictionAction");

            if(caseName.Name.ClientDetail == null || caseName.Name.ClientDetail.DebtorStatus == null)
                return false;

            return restrictionAction.Contains(caseName.Name.ClientDetail.DebtorStatus.RestrictionAction);
        }

        public static AssociatedName GetContactDetail(this CaseName caseName, IDbContext dbContext)
        {
            if (caseName == null) throw new ArgumentNullException("caseName");
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            return dbContext.Set<AssociatedName>().FirstOrDefault(an => an.RelatedNameId == caseName.NameId
                                                                               &&
                                                                               an.Relationship.Equals(
                                                                                   KnownRelations.Employs));
        }
    }
}