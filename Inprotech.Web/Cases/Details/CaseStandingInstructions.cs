using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseStandingInstructions
    {
        Task<IEnumerable<CompositeInstruction>> Retrieve(int caseId);
        Task<IEnumerable<StandingInstruction>> GetStandingInstructions(int caseId);
    }

    public class CaseStandingInstructions : ICaseStandingInstructions
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISiteControlReader _siteControls;

        public CaseStandingInstructions(IDbContext dbContext,
                                        IPreferredCultureResolver preferredCultureResolver,
                                        ISiteControlReader siteControls)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _siteControls = siteControls;
        }

        public async Task<IEnumerable<CompositeInstruction>> Retrieve(int caseId)
        {
            var homeNameNo = _siteControls.Read<int>(SiteControls.HomeNameNo);

            var @case = await _dbContext.Set<Case>()
                                        .Where(_ => _.Id == caseId)
                                        .Select(_ => new
                                        {
                                            _.PropertyTypeId,
                                            _.CountryId,
                                            OrganisationId = _.Office != null ? _.Office.OrganisationId : null
                                        })
                                        .SingleOrDefaultAsync();

            if (@case == null)
            {
                return Enumerable.Empty<CompositeInstruction>();
            }

            var organisationId = @case.OrganisationId;

            var caseNames = _dbContext.Set<CaseStandingInstructionsNamesView>()
                                      .Where(c => c.CaseId == caseId);

            var instructionTypes = _dbContext.Set<InstructionType>();
            var nameInstructions = _dbContext.Set<NameInstruction>();
            var instructions = _dbContext.Set<Instruction>();

            return (from it in instructionTypes
                    join i in instructions on it.Code equals i.InstructionTypeCode
                    join ni in nameInstructions on i.Id equals ni.InstructionId
                    join cnForNameType in caseNames on it.NameType.NameTypeCode equals cnForNameType.NameTypeCode
                    join cn1 in caseNames on it.RestrictedByTypeCode equals cn1.NameTypeCode into cnForRestrictedNameType
                    from cnForRestrictedNameTypeXt in cnForRestrictedNameType.DefaultIfEmpty()
                    where (ni.CaseId == caseId || ni.CaseId == null)
                          && (ni.Id == cnForNameType.NameId || ni.Id == organisationId || ni.Id == homeNameNo)
                          && (ni.PropertyType == @case.PropertyTypeId || ni.PropertyType == null)
                          && (ni.CountryCode == @case.CountryId || ni.CountryCode == null)
                          && (ni.RestrictedToName == (cnForRestrictedNameTypeXt != null ? cnForRestrictedNameTypeXt.NameId : (int?) null) || ni.RestrictedToName == null)
                    select new
                    {
                        InstructionTypeCode = it.Code,
                        ni.Id,

                        CompositeCode =
                            (ni.CaseId != null ? "1" : "0") +
                            (ni.Id == cnForNameType.NameId ? "1" : "0") +
                            (ni.Id == organisationId ? "1" : "0") +
                            (ni.RestrictedToName != null ? "1" : "0") +
                            (ni.PropertyType != null ? "1" : "0") +
                            (ni.CountryCode != null ? "1" : "0") +
                            DbFuncs.ConvertIntToString(ni.Id) +
                            DbFuncs.ConvertIntToString(ni.Sequence) +
                            DbFuncs.ConvertIntToString(cnForNameType.NameId)
                    }).GroupBy(_ => _.InstructionTypeCode)
                      .Select(_ => new CompositeInstruction
                      {
                          InstructionTypeCode = _.Key,
                          CompositeCode = _.Max(c => c.CompositeCode).Substring(6, 32)
                      });
        }

        public async Task<IEnumerable<StandingInstruction>> GetStandingInstructions(int caseId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var caseInstructionCompositeResult = (await Retrieve(caseId)).ToArray();

            var instruction = _dbContext.Set<Instruction>();
            var instructionType = _dbContext.Set<InstructionType>();

            var result = new List<StandingInstruction>();

            foreach (var cni in caseInstructionCompositeResult)
            {
                result.Add((from ni in _dbContext.Set<NameInstruction>()
                            join i in instruction on ni.InstructionId equals i.Id
                            join it in instructionType on i.InstructionTypeCode equals it.Code
                            where ni.Id == cni.NameNo && ni.Sequence == cni.InternalSeq
                            select new StandingInstruction
                            {
                                InstructionTypeDesc = DbFuncs.GetTranslation(it.Description, null, it.DescriptionTId, culture),
                                Description = DbFuncs.GetTranslation(i.Description, null, i.DescriptionTId, culture),
                                InstructionTypeCode = cni.InstructionTypeCode,
                                NameNo = ni.Id,
                                InternalSeq = ni.Sequence,
                                CaseId = ni.CaseId,
                                InstructionCode = ni.InstructionId
                            }).Single());
            }

            return result;
        }
    }

    public class CompositeInstruction
    {
        string _compositeCode;

        public string InstructionTypeCode { get; set; }

        public string CompositeCode
        {
            get => _compositeCode;
            set
            {
                _compositeCode = value;
                if (!string.IsNullOrWhiteSpace(_compositeCode))
                {
                    NameNo = Convert.ToInt32(_compositeCode.Substring(0, 11));
                    InternalSeq = Convert.ToInt32(_compositeCode.Substring(11, 11));
                }
            }
        }

        public int NameNo { get; set; }

        public int InternalSeq { get; set; }
    }

    public class StandingInstruction
    {
        public string InstructionTypeCode { get; set; }

        public string InstructionTypeDesc { get; set; }

        public string Description { get; set; }

        public int NameNo { get; set; }

        public int InternalSeq { get; set; }

        public int? CaseId { get; set; }

        public short? InstructionCode { get; set; }
    }
}