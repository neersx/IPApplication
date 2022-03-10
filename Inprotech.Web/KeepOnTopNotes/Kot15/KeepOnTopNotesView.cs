using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.KeepOnTopNotes.Kot15
{
    public class KeepOnTopNotesView : IKeepOnTopNotesView
    {
        readonly IDbContext _dbContext;
        readonly IDisplayFormattedName _formattedName;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;

        public KeepOnTopNotesView(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ISiteControlReader siteControlReader,
                                  ISecurityContext securityContext, IDisplayFormattedName formattedName)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _siteControlReader = siteControlReader;
            _securityContext = securityContext;
            _formattedName = formattedName;
        }

        public async Task<IEnumerable<KotNotesItem>> GetKotNotesForCase(int caseId, string program)
        {
            if (_securityContext.User.IsExternalUser) return null;

            var userId = _securityContext.User.Id;

            var culture = _preferredCultureResolver.Resolve();

            var kotProgram = (int) Enum.Parse(typeof(KotProgram), program);

            var caseWithCaseTypeConfiguredForKot = from c in _dbContext.Set<Case>()
                                                   join ct in _dbContext.Set<CaseType>() on c.TypeId equals ct.Code into ct1
                                                   from ct in ct1.DefaultIfEmpty()
                                                   join tt in _dbContext.Set<TextType>() on ct.KotTextType equals tt.Id into tt1
                                                   from tt in tt1.DefaultIfEmpty()
                                                   where (ct.Program & kotProgram) == kotProgram && c.Id == caseId
                                                   select new
                                                   {
                                                       c.Id,
                                                       c.Irn,
                                                       c.TypeId,
                                                       KotTextType = ct != null ? ct.KotTextType : null,
                                                       TextDescription = tt != null ? tt.TextDescription : null
                                                   };

            var firstKotCaseTextInCase = from ct in _dbContext.Set<CaseText>()
                                         where (ct.IsLongText == 1 && ct.LongText != null || ct.IsLongText != 1 && ct.ShortText != null) && ct.CaseId == caseId
                                         group ct by ct.Type
                                         into ctg
                                         select ctg.OrderByDescending(_ => _.Number).FirstOrDefault();

            var interimResults = await (from c in caseWithCaseTypeConfiguredForKot
                                        join ct in firstKotCaseTextInCase on new {x1 = c.Id, x2 = c.KotTextType} equals new
                                            {x1 = ct.CaseId, x2 = ct.Type}
                                        select new KotNotesItem
                                        {
                                            Note = ct.IsLongText == 1
                                                ? DbFuncs.GetTranslation(null, ct.LongText, ct.LongTextTId, culture)
                                                : DbFuncs.GetTranslation(ct.ShortText, null, ct.ShortTextTId, culture),
                                            CaseRef = c.Irn,
                                            TextType = c.TextDescription
                                        }).ToArrayAsync();

            var caseNamesNotes = await GetKotNotesForCaseNames(userId, culture, caseId, program);

            return interimResults.Concat(caseNamesNotes);
        }

        public async Task<IEnumerable<KotNotesItem>> GetKotNotesForName(int nameId, string program)
        {
            if (_securityContext.User.IsExternalUser) return null;
            var culture = _preferredCultureResolver.Resolve();
            var kotProgram = (int) Enum.Parse(typeof(KotProgram), program);
            var allowedNameTypes = new[] {KnownNameTypes.Debtor, KnownNameTypes.RenewalsDebtor};

            var nameWithCorrespondenceInstructions = from n in _dbContext.Set<Name>()
                                                     join cd in _dbContext.Set<ClientDetail>() on n.Id equals cd.Id into cd1
                                                     from cd in cd1.DefaultIfEmpty()
                                                     select new
                                                     {
                                                         n.Id,
                                                         Correspondence = cd != null ? cd.Correspondence : null,
                                                         CorrespondenceTid = cd != null ? cd.CorrespondenceTid : null
                                                     };

            var nameTypesConfiguredForKot = from nt in _dbContext.Set<NameType>()
                                            join tt in _dbContext.Set<TextType>() on nt.KotTextType equals tt.Id into tt1
                                            from tt in tt1.DefaultIfEmpty()
                                            select new
                                            {
                                                nt.NameTypeCode,
                                                nt.KotTextType,
                                                nt.Name,
                                                nt.NameTId,
                                                nt.Program,
                                                TextDescription = tt != null ? tt.TextDescription : null,
                                                TextDescriptionTId = tt != null ? tt.TextDescriptionTId : null
                                            };

            var nameTypesAllowed = _dbContext.Set<NameTypeClassification>().Where(_ => _.IsAllowed == 1);

            var caseNameTypesUsedForName = from cn in _dbContext.Set<CaseName>()
                                           where cn.NameId == nameId
                                           select cn.NameTypeId;
                
            var interimResults = await (from nt in nameTypesConfiguredForKot
                                        join n in nameWithCorrespondenceInstructions on nameId equals n.Id
                                        join txt in _dbContext.Set<NameText>() on new {n.Id, type = nt.KotTextType} equals new
                                            {txt.Id, type = txt.TextType} into txt1
                                        from txt in txt1.DefaultIfEmpty()
                                        where nt.KotTextType != null && (nt.Program & kotProgram) == kotProgram &&
                                              (caseNameTypesUsedForName.Any(cn => nt.NameTypeCode == cn) ||
                                               nameTypesAllowed.Any(ntc => ntc.NameId == n.Id && ntc.NameTypeId == nt.NameTypeCode)) && 
                                              (txt != null && txt.Text != null || n != null && n.Correspondence != null && CorrespondenceNameTypes.NameTypes.Contains(nt.KotTextType)) && 
                                              (kotProgram != (int) KotProgram.Time || kotProgram == (int) KotProgram.Time && allowedNameTypes.Contains(nt.NameTypeCode))
                                        select new
                                        {
                                            NameId = n.Id,
                                            NameTypes = DbFuncs.GetTranslation(null, nt.Name, nt.NameTId, culture),
                                            Note = txt != null
                                                ? DbFuncs.GetTranslation(null, txt.Text, txt.TextTid, culture)
                                                : DbFuncs.GetTranslation(null, n.Correspondence, n.CorrespondenceTid,
                                                                         culture),
                                            TextType = nt.TextDescription
                                        }).Where(_ => !string.IsNullOrEmpty(_.Note)).ToArrayAsync();

            var result = interimResults
                         .GroupBy(_ => new {_.NameId, _.TextType})
                         .Select(_ => new KotNotesItem
                         {
                             NameId = _.First().NameId,
                             NameTypes = string.Join(", ", _.Select(nt => nt.NameTypes)),
                             Note = _.First().Note,
                             TextType = _.First().TextType
                         }).ToArray();

            await GetFormattedName(result);

            return result;
        }

        async Task<IEnumerable<KotNotesItem>> GetKotNotesForCaseNames(int userId, string culture, int caseId, string program)
        {
            var isExternalUser = _securityContext.User.IsExternalUser;

            var kotProgram = (int) Enum.Parse(typeof(KotProgram), program);

            var screenControlName = _siteControlReader.Read<string>(SiteControls.CRMScreenControlProgram) ?? string.Empty;

            var screenControlNameTypes =
                await (from c in _dbContext.Set<Case>()
                       join ct in _dbContext.Set<CaseType>() on c.TypeId equals ct.Code
                       where ct.CrmOnly == true && c.Id == caseId
                       select c).AnyAsync()
                    ? await _dbContext.GetScreenControlNameTypes(userId, caseId, screenControlName).ToArrayAsync()
                    : new string[0];

            var caseNamesWithNameTypeHavingConfiguredForKot = from cn in _dbContext.Set<CaseName>()
                                                              join nt in _dbContext.Set<NameType>() on cn.NameTypeId equals nt.NameTypeCode
                                                              join fnt in _dbContext.FilterUserNameTypes(userId, culture, isExternalUser, false)
                                                                  on cn.NameTypeId equals fnt.NameType
                                                              where nt.KotTextType != null && (nt.Program & kotProgram) == kotProgram && cn.CaseId == caseId
                                                              select new
                                                              {
                                                                  cn.CaseId,
                                                                  cn.NameId,
                                                                  nt.KotTextType,
                                                                  nt.NameTypeCode,
                                                                  NameTypeDescription = nt.Name,
                                                                  NameTypeDescriptionTId = nt.NameTId
                                                              };

            var interimResults = await (from cn in caseNamesWithNameTypeHavingConfiguredForKot
                                        join txt in _dbContext.Set<NameText>() on new {nameId = cn.NameId, tt = cn.KotTextType} equals new
                                            {nameId = txt.Id, tt = txt.TextType} into txt1
                                        from txt in txt1.DefaultIfEmpty()
                                        join ipn in _dbContext.Set<ClientDetail>() on cn.NameId equals ipn.Id into ipn1
                                        from ipn in ipn1.DefaultIfEmpty()
                                        where (txt != null || ipn != null &&
                                                  CorrespondenceNameTypes.NameTypes.Contains(cn.KotTextType) &&
                                                  !string.IsNullOrEmpty(ipn.Correspondence))
                                              && (!screenControlNameTypes.Any() || screenControlNameTypes.Contains(cn.NameTypeCode))
                                        select new
                                        {
                                            cn.NameId,
                                            NameTypes = DbFuncs.GetTranslation(null, cn.NameTypeDescription, cn.NameTypeDescriptionTId, culture),
                                            Note = txt != null
                                                ? DbFuncs.GetTranslation(null, txt.Text, txt.TextTid, culture)
                                                : DbFuncs.GetTranslation(null, ipn.Correspondence, ipn.CorrespondenceTid, culture),
                                            TextType = cn.KotTextType
                                        }).Where(_ => !string.IsNullOrEmpty(_.Note)).ToArrayAsync();

            var result = interimResults
                         .GroupBy(_ => new {_.NameId, _.TextType})
                         .Select(_ => new KotNotesItem
                         {
                             NameId = _.First().NameId,
                             NameTypes = string.Join(", ", _.Select(nt => nt.NameTypes)),
                             Note = _.First().Note,
                             TextType = _.First().TextType
                         }).ToArray();

            await GetFormattedName(result);

            return result;
        }

        async Task GetFormattedName(KotNotesItem[] result)
        {
            if (!result.Any())
            {
                return;
            }

            var nameIds = result.Where(_ => _.NameId.HasValue).Select(_ => _.NameId.Value).ToArray();
            var formattedNames = await _formattedName.For(nameIds);
            foreach (var r in result)
            {
                if (r.NameId == null) continue;

                r.Name = formattedNames?.Get(r.NameId.Value).Name;
            }
        }
    }
}