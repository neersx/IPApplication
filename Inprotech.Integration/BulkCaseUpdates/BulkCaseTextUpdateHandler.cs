using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.GlobalCaseChange;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public interface IBulkCaseTextUpdateHandler
    {
        Task<bool> UpdateTextTypeAsync(BulkCaseUpdatesArgs request, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated,
                                       IQueryable<GlobalCaseChangeResults> gncResults);
    }

    public class BulkCaseTextUpdateHandler : IBulkCaseTextUpdateHandler
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControl;
        readonly Func<DateTime> _now;
        readonly IBatchedSqlCommand _batchedSqlCommand;

        public BulkCaseTextUpdateHandler(IDbContext dbContext, ISecurityContext securityContext, ISiteControlReader siteControl,
                                         Func<DateTime> now,
                                         IBatchedSqlCommand batchedSqlCommand)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _siteControl = siteControl;
            _now = now;
            _batchedSqlCommand = batchedSqlCommand;
        }
        public async Task<bool> UpdateTextTypeAsync(BulkCaseUpdatesArgs request, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated,
                                                    IQueryable<GlobalCaseChangeResults> gncResults)
        {
            if (request.TextType == null && request.SaveData.CaseText?.TextType == null) return false;
            if (request.TextType != null)
            {
                var reason = new BulkCaseTextUpdate { CanAppend = true, Notes = request.Notes, TextType = request.TextType };
                await UpdateCaseTextType(casesToBeUpdated.ToArray(), reason, true);
                await UpdateGncResults(gncResults);
            }

            var invalidCasesForGoodsAndServicesWithClass = new List<int>();

            if (request.SaveData.CaseText?.TextType != null)
            {
                IEnumerable<InprotechKaizen.Model.Cases.Case> cases = casesToBeUpdated;
                var caseTextData = request.SaveData.CaseText;
                if (caseTextData.TextType == KnownTextTypes.GoodsServices && !string.IsNullOrEmpty(caseTextData.Class))
                {
                    cases = casesToBeUpdated.ToArray()
                                            .Where(_ => !string.IsNullOrEmpty(_.LocalClasses) && _.LocalClasses.Split(",".ToCharArray())
                                            .Contains(caseTextData.Class)).ToArray();
                    invalidCasesForGoodsAndServicesWithClass = casesToBeUpdated.ToArray().Where(_ => cases.All(x => x.Id != _.Id)).Select(_ => _.Id).ToList();
                }

                if (!cases.Any()) return invalidCasesForGoodsAndServicesWithClass.Any();

                if (caseTextData.ToRemove)
                {
                    var lan = !string.IsNullOrWhiteSpace(caseTextData.Language) ? int.Parse(caseTextData.Language) : (int?)null;
                    var caseTextToBeUpdated = _dbContext.Set<CaseText>().Where(_ => _.Type == caseTextData.TextType
                                                                                    && _.Language == lan
                                                                                    && _.Class == caseTextData.Class
                                                                                    && cases.Any(c => c.Id == _.CaseId));
                    await _dbContext.DeleteAsync(caseTextToBeUpdated);
                }
                else
                {
                    await UpdateCaseTextType(cases.ToArray(), caseTextData, caseTextData.CanAppend);
                }

                var caseIds = cases.Select(_ => _.Id).ToArray();
                var gncResultsUpdated = gncResults.Where(_ => caseIds.Contains(_.CaseId));
                await UpdateGncResults(gncResultsUpdated);

                if (invalidCasesForGoodsAndServicesWithClass.Any())
                {
                    return true;
                }
            }
            return false;
        }

        async Task UpdateGncResults(IQueryable<GlobalCaseChangeResults> gncResults)
        {
            await _dbContext.UpdateAsync(gncResults, _ => new GlobalCaseChangeResults
            {
                CaseTextUpdated = true
            });
        }

        async Task UpdateCaseTextType(InprotechKaizen.Model.Cases.Case[] cases, BulkCaseTextUpdate ctu, bool appendText)
        {
            var keepHistory = _siteControl.Read<bool?>(SiteControls.KEEPSPECIHISTORY) ?? false;
            var notesToAppend = appendText ? $" ({_securityContext.User.Name.NameCode}: {_now().ToString("yyyyMMdd", System.Globalization.CultureInfo.InvariantCulture)})" : string.Empty;
            ctu.Notes = $"{ctu.Notes}{notesToAppend}";
            if (!keepHistory)
            {
                await UpdateCaseText(cases, ctu);
            }
            else
            {
                await AddCaseTextForExistingRows(cases, ctu);
            }
            await AddCaseText(cases, ctu);
        }

        async Task UpdateCaseText(InprotechKaizen.Model.Cases.Case[] casesToBeUpdated, BulkCaseTextUpdate ctu)
        {
            var lan = !string.IsNullOrWhiteSpace(ctu.Language) ? int.Parse(ctu.Language) : (int?)null;
            var caseList = string.Join(",", casesToBeUpdated.Select(_ => _.Id));

            var parameters = new Dictionary<string, object>
            {
                {"@textType", ctu.TextType},
                {"@text", ctu.Notes},
                {"@longFlag", ctu.Notes.Length > 254},
                {"@language", lan ?? (object) DBNull.Value},
                {"@class", ctu.Class ?? (object) DBNull.Value },
                {"@lastModified", _now()}
            };

            var updateCommand = new StringBuilder(@"Update CASETEXT set CLASS = @class, LANGUAGE = @language, MODIFIEDDATE = @lastModified,");
            updateCommand.Append(ctu.CanAppend
                                     ? @"LONGFLAG = CASE WHEN C.LONGFLAG = 1 or @longFlag = 1 or DATALENGTH(@text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)  + C.SHORTTEXT) > 508 THEN 1 ELSE 0 END,
                                    TEXT = CASE WHEN C.LONGFLAG = 1 THEN @text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)  + cast(C.TEXT as nvarchar(max)) 
                                                WHEN @longFlag = 1 THEN @text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + C.SHORTTEXT 
                                                WHEN DATALENGTH(@text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + C.SHORTTEXT) > 508 
                                                THEN @text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)  + C.SHORTTEXT
                                                ELSE NULL END,
                                    SHORTTEXT =  CASE WHEN C.LONGFLAG = 0 and @longFlag = 0 and DATALENGTH(@text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)  + C.SHORTTEXT) <= 508  
                                                THEN @text + CHAR(13) + CHAR(10)  + C.SHORTTEXT  
                                                ELSE NULL END"
                                     : @"LONGFLAG = CASE WHEN @longFlag = 1 THEN 1 ELSE 0 END,
					                    TEXT =  CASE WHEN @longFlag = 1 THEN @text ELSE NULL END,
					                    SHORTTEXT = CASE WHEN @longFlag = 0 THEN @text ELSE NULL END");

            updateCommand.Append(@" FROM CASETEXT C			
                            where C.TEXTTYPE = @textType
                            and  C.TEXTNO = (SELECT MAX(TEXTNO)FROM CASETEXT CT2
                                                WHERE CT2.CASEID = C.CASEID 
                                                AND CT2.TEXTTYPE = C.TEXTTYPE
                                                AND (CT2.CLASS = @class or (CT2.CLASS is null and @class is null))
                                                AND (CT2.LANGUAGE = @language or (CT2.LANGUAGE is null and @language is null)))
                            and (C.CLASS = @class or (C.CLASS is null and @class is null))
                            and (C.LANGUAGE = @language or (C.LANGUAGE is null and @language is null))
                            and C.CASEID in (" + caseList + ")");

            await _batchedSqlCommand.ExecuteAsync(updateCommand.ToString(), parameters);
        }

        async Task AddCaseTextForExistingRows(InprotechKaizen.Model.Cases.Case[] casesToBeUpdated, BulkCaseTextUpdate ctu)
        {
            var lan = !string.IsNullOrWhiteSpace(ctu.Language) ? int.Parse(ctu.Language) : (int?)null;
            var caseList = string.Join(",", casesToBeUpdated.Select(_ => _.Id));

            var parameters = new Dictionary<string, object>
            {
                {"@textType", ctu.TextType},
                {"@text", ctu.Notes},
                {"@longFlag", ctu.Notes.Length > 254},
                {"@language", lan ?? (object) DBNull.Value},
                {"@class", ctu.Class ?? (object) DBNull.Value },
                {"@lastModified", _now()}
            };
            var insertCommand = new StringBuilder(@"
            INSERT INTO CASETEXT(CASEID, TEXTTYPE, TEXTNO, CLASS, LANGUAGE, MODIFIEDDATE, LONGFLAG, SHORTTEXT, TEXT)
		    SELECT C.CASEID, @textType, 
		           ISNULL((SELECT MAX(TEXTNO) + 1 FROM CASETEXT CT2 WHERE CT2.CASEID = C.CASEID AND CT2.TEXTTYPE = C.TEXTTYPE), 0), 
		           @class, @language, @lastModified, ");

            insertCommand.Append(ctu.CanAppend
                                     ? @"CASE WHEN C.LONGFLAG = 1 or @longFlag = 1 or DATALENGTH(@text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)  + C.SHORTTEXT) > 508 THEN 1 ELSE 0 END,
		                           CASE WHEN C.LONGFLAG = 0 and @longFlag = 0 and DATALENGTH(@text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)  + C.SHORTTEXT) <= 508 
                                        THEN @text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)  + C.SHORTTEXT ELSE NULL END,
					               CASE WHEN C.LONGFLAG = 1 THEN @text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)  + cast(C.TEXT as nvarchar(max)) 
		                                     WHEN @longFlag = 1 THEN @text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)  + C.SHORTTEXT 
		                                     WHEN DATALENGTH(@text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)  + C.SHORTTEXT) > 508 
		                                        THEN @text + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)  + C.SHORTTEXT
		                                     ELSE NULL END"
                                     : @"CASE WHEN @longFlag = 1  THEN 1 ELSE 0 END,
                                    CASE WHEN @longFlag = 0 THEN @text ELSE NULL END,
                                    CASE WHEN @longFlag = 1 THEN @text ELSE NULL END");

            insertCommand.Append(@" FROM CASETEXT C			
                            where C.TEXTTYPE = @textType
                            and  C.TEXTNO = ISNULL((SELECT MAX(TEXTNO)FROM CASETEXT CT2
                                                WHERE CT2.CASEID = C.CASEID 
                                            AND CT2.TEXTTYPE = C.TEXTTYPE
                                            AND (CT2.CLASS = @class or (CT2.CLASS is null and @class is null))
                                            AND (CT2.LANGUAGE = @language or (CT2.LANGUAGE is null and @language is null))), 0)
                            and (C.CLASS = @class or (C.CLASS is null and @class is null))
                            and (C.LANGUAGE = @language or (C.LANGUAGE is null and @language is null))
                            and C.CASEID in (" + caseList + ")");

            await _batchedSqlCommand.ExecuteAsync(insertCommand.ToString(), parameters);
        }

        async Task AddCaseText(InprotechKaizen.Model.Cases.Case[] casesToBeUpdated, BulkCaseTextUpdate ctu)
        {
            var lan = !string.IsNullOrWhiteSpace(ctu.Language) ? int.Parse(ctu.Language) : (int?)null;
            var caseList = string.Join(",", casesToBeUpdated.Select(_ => _.Id));

            var parameters = new Dictionary<string, object>
            {
                {"@textType", ctu.TextType},
                {"@text", ctu.Notes},
                {"@longFlag", ctu.Notes.Length > 254},
                {"@language", lan ?? (object) DBNull.Value},
                {"@class", ctu.Class ?? (object) DBNull.Value },
                {"@lastModified", _now()}
            };

            var insertCommand = @"
            INSERT INTO CASETEXT(CASEID, TEXTTYPE, TEXTNO, CLASS, LANGUAGE, MODIFIEDDATE, LONGFLAG, SHORTTEXT, TEXT)
		    SELECT C.CASEID, @textType, ISNULL((SELECT MAX(TEXTNO) + 1 FROM CASETEXT CT2 WHERE CT2.CASEID = C.CASEID AND CT2.TEXTTYPE = @textType), 0), 
		           @class, @language, @lastModified, @longFlag,
                   CASE WHEN @longFlag = 0 THEN @text ELSE NULL END,
                   CASE WHEN @longFlag = 1 THEN @text ELSE NULL END
                   FROM CASES C	
                   left join CASETEXT CT on (CT.TEXTTYPE = @textType 
                                and (CT.CLASS = @class or (CT.CLASS is null and @class is null))
                                and (CT.LANGUAGE = @language or (CT.LANGUAGE is null and @language is null))
                                and CT.CASEID = C.CASEID)
                   where (@class is null or @class in (Select T.Parameter from dbo.fn_Tokenise(C.LOCALCLASSES, ',') T))
                        and C.CASEID in (" + caseList + @") 
                        and CT.CASEID is null";

            await _batchedSqlCommand.ExecuteAsync(insertCommand, parameters);
        }
    }
}
