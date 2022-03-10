using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.StandingInstructions;
using Newtonsoft.Json;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseViewStandingInstructions
    {
        Task<IEnumerable<CaseViewStandingInstruction>> GetCaseStandingInstructions(int caseId, string[] instructionTypes = null);
    }

    public class CaseViewStandingInstructions : ICaseViewStandingInstructions
    {
        readonly ICaseStandingInstructions _caseStandingInstructions;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly ISiteConfiguration _siteConfiguration;

        public CaseViewStandingInstructions(IDbContext dbContext,
                                            IPreferredCultureResolver preferredCultureResolver,
                                            ISiteConfiguration siteConfiguration,
                                            ISecurityContext securityContext,
                                            ICaseStandingInstructions caseViewStandingInstructions)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _siteConfiguration = siteConfiguration;
            _securityContext = securityContext;
            _caseStandingInstructions = caseViewStandingInstructions;
        }

        public async Task<IEnumerable<CaseViewStandingInstruction>> GetCaseStandingInstructions(int caseId, string[] instructionTypes = null)
        {
            var culture = _preferredCultureResolver.Resolve();
            var workdayFlag = _siteConfiguration.HomeCountry().WorkDayFlag;
            var workdays = GetWeeklyWorkDays(workdayFlag ?? 0);

            var composites = (await _caseStandingInstructions.Retrieve(caseId)).ToArray();

            var result = new List<CaseViewStandingInstruction>();

            foreach (var ci in composites)
            {
                if (instructionTypes != null && !instructionTypes.Contains(ci.InstructionTypeCode))
                {
                    continue;
                }

                result.Add((from ni in _dbContext.Set<NameInstruction>()
                            join it in _dbContext.Set<InstructionType>() on ci.InstructionTypeCode equals it.Code
                            join i in _dbContext.Set<Instruction>() on ni.InstructionId equals i.Id into i1
                            from i in i1
                            join n in _dbContext.Set<Name>() on ci.NameNo equals n.Id into n1
                            from n in n1.DefaultIfEmpty()
                            where ni.Id == ci.NameNo && ni.Sequence == ci.InternalSeq
                            select new CaseViewStandingInstruction
                            {
                                InstructionTypeDesc = DbFuncs.GetTranslation(it.Description, null, it.DescriptionTId, culture),
                                InstructionTypeCode = ci.InstructionTypeCode,
                                InstructionCode = ni.InstructionId,
                                Description = DbFuncs.GetTranslation(i.Description, null, i.DescriptionTId, culture),
                                NameNo = ni.Id,
                                CaseId = ni.CaseId,
                                DefaultedFrom = ni.CaseId == null ? n.LastName : string.Empty,
                                InternalSeq = ni.Sequence,
                                Period1Amt = ni.Period1Amt,
                                Period1Type = ni.Period1Type,
                                Period2Amt = ni.Period2Amt,
                                Period2Type = ni.Period2Type,
                                Period3Amt = ni.Period3Amt,
                                Period3Type = ni.Period3Type,
                                Adjustment = ni.Adjustment,
                                AdjustDayRaw = ni.AdjustDay,
                                AdjustStartMonthRaw = ni.AdjustStartMonth,
                                AdjustDayOfWeekRaw = ni.AdjustDayOfWeek,
                                AdjustToDate = ni.AdjustToDate,
                                StandingInstructionText = ni.StandingInstructionText
                            }).Single());
            }

            var tcTranslated = (from g in (from tc in _dbContext.Set<TableCode>()
                                           where tc.TableTypeId == (int) TableTypes.MonthsOfYear ||
                                                 tc.TableTypeId == (int) TableTypes.DaysOfWeek ||
                                                 tc.TableTypeId == (int) TableTypes.PeriodType
                                           select new
                                           {
                                               tc.TableTypeId,
                                               tc.UserCode,
                                               NameTranslated = DbFuncs.GetTranslation(tc.Name, null, tc.NameTId, culture)
                                           }).ToArray()
                                group g by g.TableTypeId
                                into g1
                                select new
                                {
                                    g1.Key,
                                    Value = g1.ToDictionary(k => k.UserCode, v => v.NameTranslated)
                                })
                .ToDictionary(k => k.Key, v => v.Value);

            var adjustmentTranslated = (from a in _dbContext.Set<DateAdjustment>()
                                        select new
                                        {
                                            a.Id,
                                            Translated = DbFuncs.GetTranslation(a.Description, null, a.DescriptionTId, culture)
                                        })
                .ToDictionary(k => k.Id, v => v.Translated);

            foreach (var r in result)
            {
                r.IsExternalUser = _securityContext.User.IsExternalUser;

                r.Period1Type = tcTranslated[(int) TableTypes.PeriodType].Get(r.Period1Type);
                r.Period2Type = tcTranslated[(int) TableTypes.PeriodType].Get(r.Period2Type);
                r.Period3Type = tcTranslated[(int) TableTypes.PeriodType].Get(r.Period3Type);

                r.AdjustDay = GetAdjustmentDay(r.NameNo, r.AdjustDayRaw, r.NameNo, r.Adjustment);
                r.AdjustStartMonthByte = GetAdjustmentStartMonth(r.NameNo, r.AdjustStartMonthRaw, r.NameNo, r.Adjustment);
                r.AdjustDayOfWeekByte = GetAdjustmentDayOfWeek(r.NameNo, r.AdjustDayOfWeekRaw, r.NameNo, r.Adjustment, workdays);

                r.ShowAdjustDay = KnownAdjustment.AllowedForDay.Contains(r.Adjustment);
                r.ShowAdjustStartMonth = KnownAdjustment.AllowedForMonth.Contains(r.Adjustment);
                r.ShowAdjustDayOfWeek = KnownAdjustment.AllowedForDayOrWeek.Contains(r.Adjustment);
                r.ShowAdjustToDate = r.Adjustment == KnownAdjustment.UserDate;

                r.Adjustment = adjustmentTranslated.Get(r.Adjustment);
                r.AdjustStartMonth = tcTranslated[(int) TableTypes.MonthsOfYear].Get(r.AdjustStartMonthByte?.ToString());
                r.AdjustDayOfWeek = tcTranslated[(int) TableTypes.DaysOfWeek].Get(r.AdjustDayOfWeekByte?.ToString());
            }

            return result;
        }

        static int GetWeeklyWorkDays(short workDayFlag)
        {
            var flags = new Dictionary<DayOfWeek, int>
            {
                {DayOfWeek.Saturday, 1},
                {DayOfWeek.Sunday, 2},
                {DayOfWeek.Monday, 4},
                {DayOfWeek.Tuesday, 8},
                {DayOfWeek.Wednesday, 16},
                {DayOfWeek.Thursday, 32},
                {DayOfWeek.Friday, 64}
            };
            var weeklyOffDays = flags.Where(_ => (workDayFlag & _.Value) == 0).Select(_ => _.Key).ToList();

            return flags.Count - weeklyOffDays.Count;
        }

        static int? GetAdjustmentDay(int? caseNameNo, byte? adjustDay, int instructionNameNo, string adjustment)
        {
            var adjustmentDay = caseNameNo == instructionNameNo
                ? adjustDay ?? 1
                : Math.Abs((caseNameNo ?? 0) % 28) + 1;

            return KnownAdjustment.AllowedForDay.Contains(adjustment) ? adjustmentDay : null;
        }

        static int? GetAdjustmentStartMonth(int? caseNameNo, byte? adjustStartMonth, int instructionNameNo, string adjustment)
        {
            var adjustmentMonth = caseNameNo == instructionNameNo
                ? adjustStartMonth ?? 12
                : Math.Abs((caseNameNo ?? 11) % 12) + 1;

            int? adjMon = null;

            switch (adjustment)
            {
                case KnownAdjustment.Annual:
                    adjMon = adjustmentMonth;
                    break;
                case KnownAdjustment.HalfYearly when adjustmentMonth <= 6:
                    adjMon = adjustStartMonth + 6;
                    break;
                case KnownAdjustment.HalfYearly:
                    adjMon = adjustmentMonth;
                    break;
                case KnownAdjustment.Quarterly:
                    switch (adjustmentMonth)
                    {
                        case 1:
                        case 4:
                        case 7:
                            adjMon = 10;
                            break;
                        case 2:
                        case 5:
                        case 8:
                            adjMon = 11;
                            break;
                        case 3:
                        case 6:
                        case 9:
                            adjMon = 12;
                            break;
                        default:
                            adjMon = adjustmentMonth;
                            break;
                    }

                    break;
                case KnownAdjustment.BiMonthly:
                    adjMon = adjustmentMonth;
                    break;
                case KnownAdjustment.UserDate:
                    break;
                default:
                {
                    if (adjustment != null)
                    {
                        adjMon = 12;
                    }

                    break;
                }
            }

            return adjMon ?? adjustStartMonth;
        }

        static int? GetAdjustmentDayOfWeek(int? caseNameNo, byte? adjustDayOfWeek, int instructionNameNo, string adjustment, int workdays)
        {
            var adjustmentWeekDay = caseNameNo == instructionNameNo
                ? adjustDayOfWeek ?? 3
                : Math.Abs((caseNameNo ?? 7) % workdays) + 1;

            return KnownAdjustment.AllowedForDayOrWeek.Contains(adjustment) ? adjustmentWeekDay : adjustDayOfWeek;
        }
    }

    public class CaseViewStandingInstruction
    {
        public string InstructionTypeCode { get; set; }

        public string InstructionTypeDesc { get; set; }

        public string Description { get; set; }

        public int NameNo { get; set; }

        public int InternalSeq { get; set; }

        public int? CaseId { get; set; }

        public string DefaultedFrom { get; set; }

        public short? InstructionCode { get; set; }

        public short? Period1Amt { get; set; }

        public string Period1Type { get; set; }

        public short? Period2Amt { get; set; }

        public string Period2Type { get; set; }

        public short? Period3Amt { get; set; }

        public string Period3Type { get; set; }

        public string Adjustment { get; set; }

        public int? AdjustDay { get; set; }

        public bool ShowAdjustDay { get; set; }

        public int? AdjustStartMonthByte { get; set; }

        public int? AdjustDayOfWeekByte { get; set; }

        public string AdjustStartMonth { get; set; }

        public bool ShowAdjustStartMonth { get; set; }

        public string AdjustDayOfWeek { get; set; }

        public bool ShowAdjustDayOfWeek { get; set; }

        [JsonIgnore]
        public byte? AdjustDayRaw { get; set; }

        [JsonIgnore]
        public byte? AdjustStartMonthRaw { get; set; }

        [JsonIgnore]
        public byte? AdjustDayOfWeekRaw { get; set; }

        public DateTime? AdjustToDate { get; set; }

        public bool ShowAdjustToDate { get; set; }

        public string StandingInstructionText { get; set; }

        public bool IsExternalUser { get; set; }
    }
}