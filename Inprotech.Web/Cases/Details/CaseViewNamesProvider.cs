using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Flags = InprotechKaizen.Model.KnownNameTypeColumnFlags;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseViewNamesProvider
    {
        Task<IEnumerable<CaseViewName>> GetNames(int caseId, string[] requestedTypeCodes, int screenCriteriaKey);
    }

    public class CaseViewNamesProvider : ICaseViewNamesProvider
    {
        static readonly string[] DebtorTypes = {KnownNameTypes.Debtor, KnownNameTypes.RenewalsDebtor};
        readonly IDbContext _dbContext;
        readonly IFormattedNameAddressTelecom _formattedNameAddressTelecom;
        readonly INameAuthorization _nameAuthorization;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public CaseViewNamesProvider(IDbContext dbContext,
                                     ISecurityContext securityContext,
                                     INameAuthorization nameAuthorization,
                                     IFormattedNameAddressTelecom formattedNameAddressTelecom,
                                     IPreferredCultureResolver preferredCultureResolver,
                                     ITaskSecurityProvider taskSecurityProvider)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _nameAuthorization = nameAuthorization;
            _formattedNameAddressTelecom = formattedNameAddressTelecom;
            _preferredCultureResolver = preferredCultureResolver;
            _taskSecurityProvider = taskSecurityProvider;
        }

        public async Task<IEnumerable<CaseViewName>> GetNames(int caseId, string[] requestedTypeCodes, int screenCriteriaKey)
        {
            if (requestedTypeCodes == null) throw new ArgumentNullException(nameof(requestedTypeCodes));

            var culture = _preferredCultureResolver.Resolve();

            var interim = await GetNames(caseId, requestedTypeCodes, _securityContext.User, culture).ToArrayAsync();

            var mainNameIds = interim.Select(_ => _.NameId).Distinct().ToArray();

            var nameIds = new int[] { }
                          .Union(mainNameIds)
                          .Union(interim.Where(_ => _.AttentionId.HasValue).Select(_ => (int) _.AttentionId))
                          .Distinct().ToArray();

            var addressIds = interim.Where(_ => _.AddressId.HasValue)
                                    .Select(_ => (int) _.AddressId)
                                    .Distinct().ToArray();

            var filteredNames = _securityContext.User.IsExternalUser ? mainNameIds : (await _nameAuthorization.AccessibleNames(mainNameIds)).ToArray();

            var name = await _formattedNameAddressTelecom.GetFormatted(nameIds, NameStyles.FirstNameThenFamilyName);

            var formattedAddresses = await _formattedNameAddressTelecom.GetAddressesFormatted(addressIds);

            return from i in interim
                   let canViewName = filteredNames.Contains(i.NameId)
                   let requiredAddressId = IfRequired(i.AddressId, Flags.DisplayAddress, i.CustomDisplayFlags, canViewName)
                   select new CaseViewName
                   {
                       Id = i.Id,
                       Name = canViewName ? name[i.Id].Name : string.Empty,
                       NameAndCode = canViewName ? i.ShowNameCode.Format(name[i.Id].Name, name[i.Id].NameCode) : string.Empty,
                       Attention = canViewName ? i.AttentionId == null ? null : name[(int) i.AttentionId].Name : string.Empty,
                       AttentionId = canViewName ? i.AttentionId : null,
                       Type = i.Type,
                       TypeId = i.TypeId,
                       Sequence = i.Sequence,
                       NameVariant = i.NameVariant,
                       DisplayFlags = i.CustomDisplayFlags,
                       IsAttentionDerived = i.IsAttentionNameDerived,
                       IsAddressInherited = i.AddressId != null && i.AddressId != i.Step1AddressId,
                       IsInherited = i.IsInherited,
                       Address = canViewName ? requiredAddressId != null ? formattedAddresses[requiredAddressId.GetValueOrDefault()].Address : null : null,
                       Reference = IfRequired(i.Reference, Flags.DisplayReferenceNumber, i.CustomDisplayFlags, canViewName),
                       Comments = IfRequired(i.Comments, Flags.DisplayRemarks, i.CustomDisplayFlags, canViewName),
                       CommenceDate = IfRequired(i.CommenceDate, Flags.DisplayDateCommenced, i.CustomDisplayFlags, canViewName),
                       AssignDate = IfRequired(i.AssignDate, Flags.DisplayAssignDate, i.CustomDisplayFlags, canViewName),
                       ExpiryDate = IfRequired(i.ExpiryDate, Flags.DisplayDateCeased, i.CustomDisplayFlags, canViewName),
                       BillingPercentage = IfRequired(i.BillingPercentage, Flags.DisplayBillPercentage, i.CustomDisplayFlags, canViewName),
                       Email = IfRequired(name[i.AttentionId ?? i.Id].MainEmail ?? name[i.Id].MainEmail, Flags.DisplayTelecom, i.CustomDisplayFlags, canViewName),
                       Phone = IfRequired(name[i.AttentionId ?? i.Id].MainPhone ?? name[i.Id].MainPhone, Flags.DisplayTelecom, i.CustomDisplayFlags, canViewName),
                       Nationality = IfRequired(name[i.Id].Nationality, Flags.DisplayNationality, i.CustomDisplayFlags, canViewName),
                       ShouldCheckRestrictions = i.ShouldCheckRestrictions,
                       Website = name[i.Id].WebAddress,
                       CanView = canViewName
                   };
        }

        static T IfRequired<T>(T value, int flag, int flagValue, bool hasAccess)
        {
            return hasAccess && ShouldDisplay(flag, flagValue) ? value : default(T);
        }

        static bool ShouldDisplay(int flag, int flagValue)
        {
            return Convert.ToBoolean(flag & flagValue);
        }

        IQueryable<InterimCaseViewName> GetNames(int caseId, string[] requestedTypeCodes, User user, string culture)
        {
            if (requestedTypeCodes == null) throw new ArgumentNullException(nameof(requestedTypeCodes));

            var userId = user.Id;
            var isExternal = user.IsExternalUser;
            var noRequestedCode = !requestedTypeCodes.Any();
            var task = _securityContext.User.IsExternalUser ? ApplicationTask.EmailOurCaseContact : ApplicationTask.EmailCaseResponsibleStaff;
            var shouldPopulateTelecom = _taskSecurityProvider.HasAccessTo(task);

            var filteredNameTypes = from nt in _dbContext.Set<NameType>()
                                    join fnt in _dbContext.FilterUserNameTypes(userId, culture, isExternal, false)
                                        on nt.NameTypeCode equals fnt.NameType
                                    where noRequestedCode || requestedTypeCodes.Contains(nt.NameTypeCode)
                                    select nt;

            var relatedByNameTypeInheritance = _dbContext.Set<AssociatedName>();

            var sendBillsToSelf = from an in _dbContext.Set<AssociatedName>()
                                  where an.Relationship == KnownRelations.SendBillsTo &&
                                        an.RelatedNameId == an.Id
                                  select an;

            var others = from cn in _dbContext.Set<CaseName>()
                         join n in _dbContext.Set<Name>() on cn.NameId equals n.Id into nJ
                         from n in nJ
                         join nt in filteredNameTypes on cn.NameTypeId equals nt.NameTypeCode into nt1
                         from nt in nt1
                         where cn.CaseId == caseId && !DebtorTypes.Contains(nt.NameTypeCode)
                         select new InterimCaseViewName
                         {
                             Id = cn.NameId,
                             Type = DbFuncs.GetTranslation(nt.Name, null, nt.NameTId, culture),
                             TypeId = nt.NameTypeCode,
                             Sequence = cn.Sequence,
                             NameId = cn.NameId,
                             Step1AttentionId = cn.AttentionNameId,
                             Step2AttentionId = null,
                             Step3AttentionId = null,
                             Step4AttentionId = null,
                             DeriveCorrName = cn.IsDerivedAttentionName == 1,
                             Reference = cn.Reference,
                             RawNameVariant = cn.NameVariant == null
                                 ? null
                                 : cn.NameVariant.NameVariantDesc,
                             FirstNameVariant = cn.NameVariant == null
                                 ? null
                                 : cn.NameVariant.FirstNameVariant,
                             Step1AddressId = cn.Address != null ? (int?) cn.Address.Id : null,
                             Step2AddressId = null,
                             Step3AddressId = null,
                             Step4AddressId = n.PostalAddressId,
                             Order = nt.PriorityOrder,
                             Flags = nt.ColumnFlag ?? 0,
                             ShowNameCodeRaw = (decimal) (nt.ShowNameCode == null ? 0 : nt.ShowNameCode),
                             IsInherited = cn.IsInherited == 1,
                             ShouldCheckRestrictions = nt.IsNameRestricted == 1,
                             Comments = cn.Remarks,
                             BillingPercentage = (int?) cn.BillingPercentage,
                             AssignDate = cn.AssignmentDate,
                             CommenceDate = cn.StartingDate,
                             ExpiryDate = cn.ExpiryDate,
                             IsNationalityRequired = nt.NationalityFlag,
                             IsTelecomRequired = shouldPopulateTelecom,
                             IsExternal = isExternal
                         };

            var debtors = from cn in _dbContext.Set<CaseName>()
                          join n in _dbContext.Set<Name>() on cn.NameId equals n.Id into nJ
                          from n in nJ
                          join nt in filteredNameTypes on cn.NameTypeId equals nt.NameTypeCode into nt1
                          from nt in nt1
                          join an2 in relatedByNameTypeInheritance on new
                              {
                                  Id = cn.InheritedFromNameId,
                                  Relationship = cn.InheritedFromRelationId,
                                  cn.NameId,
                                  Sequence = cn.InheritedFromSequence
                              }
                              equals new
                              {
                                  Id = (int?) an2.Id,
                                  an2.Relationship,
                                  NameId = an2.RelatedNameId,
                                  Sequence = (short?) an2.Sequence
                              }
                              into an2J
                          from an2 in an2J.DefaultIfEmpty()
                          join an3 in sendBillsToSelf on cn.NameId equals an3.Id into an3J
                          from an3 in an3J.Where(_ => an2 == null).DefaultIfEmpty()
                          where cn.CaseId == caseId && DebtorTypes.Contains(nt.NameTypeCode)
                          select new InterimCaseViewName
                          {
                              Id = cn.NameId,
                              Type = DbFuncs.GetTranslation(nt.Name, null, nt.NameTId, culture),
                              TypeId = nt.NameTypeCode,
                              Sequence = cn.Sequence,
                              NameId = cn.NameId,
                              Step1AttentionId = cn.AttentionNameId,
                              Step2AttentionId = an2 != null ? an2.ContactId : null,
                              Step3AttentionId = an3 != null ? an3.ContactId : null,
                              Step4AttentionId = n.MainContactId,
                              DeriveCorrName = cn.IsDerivedAttentionName == 1,
                              Reference = cn.Reference,
                              RawNameVariant = cn.NameVariant == null
                                  ? null
                                  : cn.NameVariant.NameVariantDesc,
                              FirstNameVariant = cn.NameVariant == null
                                  ? null
                                  : cn.NameVariant.FirstNameVariant,
                              Step1AddressId = cn.Address != null ? (int?) cn.Address.Id : null,
                              Step2AddressId = an2 != null ? an2.PostalAddressId : null,
                              Step3AddressId = an3 != null ? an3.PostalAddressId : null,
                              Step4AddressId = n.PostalAddressId,
                              Order = nt.PriorityOrder,
                              Flags = nt.ColumnFlag ?? 0,
                              ShowNameCodeRaw = (decimal) (nt.ShowNameCode == null ? 0 : nt.ShowNameCode),
                              IsInherited = cn.IsInherited == 1,
                              ShouldCheckRestrictions = nt.IsNameRestricted == 1,
                              Comments = cn.Remarks,
                              BillingPercentage = (int?) cn.BillingPercentage,
                              AssignDate = cn.AssignmentDate,
                              CommenceDate = cn.StartingDate,
                              ExpiryDate = cn.ExpiryDate,
                              IsNationalityRequired = nt.NationalityFlag,
                              IsTelecomRequired = shouldPopulateTelecom,
                              IsExternal = isExternal
                          };

            return from n in others.Union(debtors)
                   orderby n.Order, n.Type, n.Sequence
                   select n;
        }
        
        class InterimCaseViewName
        {
            public int Id { get; set; }
            public string Type { get; set; }
            public string TypeId { get; set; }
            public short Sequence { get; set; }
            public int NameId { get; set; }
            public int? AttentionId => Step1AttentionId ?? Step2AttentionId ?? Step3AttentionId ?? Step4AttentionId;
            public int? Step1AttentionId { get; set; }
            public int? Step2AttentionId { get; set; }
            public int? Step3AttentionId { get; set; }
            public int? Step4AttentionId { get; set; }
            public bool DeriveCorrName { get; set; }
            public bool IsAttentionNameDerived => DeriveCorrName && AttentionId != null;
            public string Reference { get; set; }
            public string NameVariant => (RawNameVariant ?? string.Empty) + (!string.IsNullOrWhiteSpace(FirstNameVariant) ? ", " + FirstNameVariant : string.Empty);
            public string RawNameVariant { get; set; }
            public string FirstNameVariant { get; set; }
            public int? AddressId => Step1AddressId ?? Step2AddressId ?? Step3AddressId ?? Step4AddressId;
            public int? Step1AddressId { get; set; }
            public int? Step2AddressId { get; set; }
            public int? Step3AddressId { get; set; }
            public int? Step4AddressId { get; set; }
            public int Order { get; set; }
            public short Flags { get; set; }
            public decimal ShowNameCodeRaw { get; set; }
            public ShowNameCode ShowNameCode => (ShowNameCode) Convert.ToInt32(ShowNameCodeRaw);
            public bool IsInherited { get; set; }
            public bool ShouldCheckRestrictions { get; set; }
            public string Comments { get; set; }
            public int? BillingPercentage { get; set; }
            public DateTime? CommenceDate { get; set; }
            public DateTime? AssignDate { get; set; }
            public DateTime? ExpiryDate { get; set; }
            public bool IsNationalityRequired { get; set; }
            public bool IsTelecomRequired { get; set; }
            public bool IsExternal { get; set; }
            public string Website { get; set; }

            public short CustomDisplayFlags
            {
                get
                {
                    var f = Flags;
                    if (IsNationalityRequired) f |= KnownNameTypeColumnFlags.DisplayNationality;
                    if (IsTelecomRequired) f |= KnownNameTypeColumnFlags.DisplayTelecom;
                    if (IsExternal) f &= ~KnownNameTypeColumnFlags.DisplayRemarks;
                    return f;
                }
            }
        }
    }

    public class CaseViewName
    {
        public int Id { get; set; }
        public string Type { get; set; }
        public string TypeId { get; set; }
        public short Sequence { get; set; }
        public string Name { get; set; }
        public string NameAndCode { get; set; }
        public string Attention { get; set; }
        public int? AttentionId { get; set; }
        public string Reference { get; set; }
        public string NameVariant { get; set; }
        public string Address { get; set; }
        public short DisplayFlags { get; set; }
        public bool IsAttentionDerived { get; set; }
        public bool IsAddressInherited { get; set; }
        public bool IsInherited { get; set; }
        public string Comments { get; set; }
        public int? BillingPercentage { get; set; }
        public DateTime? CommenceDate { get; set; }
        public DateTime? AssignDate { get; set; }
        public DateTime? ExpiryDate { get; set; }
        public bool ShouldCheckRestrictions { get; set; }
        public string Nationality { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        public string Website { get; set; }
        public bool CanView { get; set; }
        public bool CanViewAttention { get; set; }
    }
}