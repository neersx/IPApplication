using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/questions")]
    public class QuestionsPicklistController : ApiController
    {
        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Question",
                SortDir = "asc"
            });

        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IStaticTranslator _staticTranslator;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public QuestionsPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IStaticTranslator staticTranslator, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _staticTranslator = staticTranslator;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(QuestionItem), ApplicationTask.MaintainQuestion)]
        [PicklistMaintainabilityActions(allowDuplicate: false)]
        public async Task<PagedResults> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var queryParams = SortByParameters.Extend(queryParameters);
            var culture = _preferredCultureResolver.Resolve();
            var responseTypes = GetResponseTypes();
            var periodTypeTableCodes = _dbContext.Set<TableCode>()
                                                 .Where(_ => _.TableTypeId == (int)TableTypes.PeriodType)
                                                 .Select(_ => new { _.UserCode, PeriodType = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture) });

            var initial = from d in _dbContext.Set<Question>()
                          join tc in _dbContext.Set<TableType>() on d.TableType equals tc.Id into tcData
                          from tcd in tcData.DefaultIfEmpty()
                          select new
                          {
                              d.Id,
                              Question = DbFuncs.GetTranslation(d.QuestionString, null, d.QuestionTid, culture),
                              Instructions = DbFuncs.GetTranslation(d.Instructions, null, d.InstructionsTid, culture),
                              d.Code,
                              d.YesNoRequired,
                              d.PeriodTypeRequired,
                              d.CountRequired,
                              d.AmountRequired,
                              d.TextRequired,
                              d.EmployeeRequired,
                              d.TableType,
                              ListSelection = tcd != null ? DbFuncs.GetTranslation(tcd.Name, null, tcd.NameTId, culture) : null,
                              PeriodTypeKey = d.PeriodTypeRequired == 4 ? "D" : d.PeriodTypeRequired == 5 ? "M" : d.PeriodTypeRequired == 6 ? "Y" : null
                          };

            var query = from d in initial
                        join p in periodTypeTableCodes on d.PeriodTypeKey equals p.UserCode into ptData
                        from ptd in ptData.DefaultIfEmpty()
                        select new
                        {
                            d.Id,
                            d.Question,
                            d.Instructions,
                            d.Code,
                            d.YesNoRequired,
                            d.PeriodTypeRequired,
                            d.CountRequired,
                            d.AmountRequired,
                            d.TextRequired,
                            d.EmployeeRequired,
                            d.TableType,
                            d.ListSelection,
                            PeriodType = ptd != null ? ptd.PeriodType : null
                        };

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(_ => (_.Question ?? string.Empty).ToLower().Contains(search.ToLower()) || (_.Code ?? string.Empty).ToLower().Contains(search.ToLower()));
            }

            var list = await query.Select(p => new QuestionItem
            {
                Key = p.Id,
                Question = p.Question,
                Instructions = p.Instructions,
                Code = p.Code,
                YesNo = p.YesNoRequired,
                Period = p.PeriodTypeRequired,
                Count = p.CountRequired,
                Amount = p.AmountRequired,
                Text = p.TextRequired,
                Staff = p.EmployeeRequired,
                List = p.ListSelection,
                PeriodValue = p.PeriodType
            }).ToArrayAsync();

            foreach (var item in list)
            {
                item.YesNoValue = item.YesNo.HasValue ? responseTypes[(short)item.YesNo.Value] : null;
                item.CountValue = item.Count.HasValue ? responseTypes[(short)item.Count.Value] : null;
                item.AmountValue = item.Amount.HasValue ? responseTypes[(short)item.Amount.Value] : null;
                item.TextValue = item.Text.HasValue ? responseTypes[(short)item.Text.Value] : null;
                item.StaffValue = item.Staff.HasValue ? responseTypes[(short)item.Staff.Value] : null;
                item.PeriodValue = item.Period.HasValue ? string.IsNullOrWhiteSpace(item.PeriodValue) ? responseTypes[(short)item.Period.Value] : item.PeriodValue : null;
            }

            return Helpers.GetPagedResults(list, queryParams, null, null, null);
        }

        Dictionary<short, string> GetResponseTypes()
        {
            return new Dictionary<short, string>
            {
                { 0, _staticTranslator.TranslateWithDefault("picklist.question.types.hide", _preferredCultureResolver.ResolveAll()) },
                { 1, _staticTranslator.TranslateWithDefault("picklist.question.types.mandatory", _preferredCultureResolver.ResolveAll()) },
                { 2, _staticTranslator.TranslateWithDefault("picklist.question.types.optional", _preferredCultureResolver.ResolveAll()) },
                { 4, _staticTranslator.TranslateWithDefault("picklist.question.types.defaultToYes", _preferredCultureResolver.ResolveAll()) },
                { 5, _staticTranslator.TranslateWithDefault("picklist.question.types.defaultToNo", _preferredCultureResolver.ResolveAll()) }
            };

        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(QuestionItem), ApplicationTask.MaintainQuestion)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route("{id}")]
        [PicklistPayload(typeof(QuestionItem), ApplicationTask.MaintainQuestion)]
        public async Task<QuestionItem> Question(int id)
        {
            var culture = _preferredCultureResolver.Resolve();
            return await (from d in _dbContext.Set<Question>()
                          where d.Id == id
                          select new QuestionItem
                          {
                              Key = d.Id,
                              Question = DbFuncs.GetTranslation(d.QuestionString, null, d.QuestionTid, culture),
                              Instructions = DbFuncs.GetTranslation(d.Instructions, null, d.InstructionsTid, culture),
                              Code = d.Code,
                              YesNo = d.YesNoRequired,
                              Period = d.PeriodTypeRequired,
                              Count = d.CountRequired,
                              Amount = d.AmountRequired,
                              Text = d.TextRequired,
                              Staff = d.EmployeeRequired,
                              ListType = d.TableType
                          }).SingleAsync();
        }

        [HttpGet]
        [Route("view")]
        public async Task<dynamic> GetViewData()
        {
            var culture = _preferredCultureResolver.Resolve();
            var periodTypeTableCodes = await _dbContext.Set<TableCode>()
                                                 .Where(_ => _.TableTypeId == (int)TableTypes.PeriodType)
                                                 .Select(_ => new { _.UserCode, PeriodType = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture) })
                                                 .ToArrayAsync();

            var tableTypes = await _dbContext.Set<TableType>()
                                       .Select(t => new { Key = t.Id, Value = DbFuncs.GetTranslation(t.Name, null, t.NameTId, culture) })
                                       .OrderBy(_ => _.Value)
                                       .ToArrayAsync();
            return new
            {
                TableTypes = tableTypes,
                PeriodTypes = periodTypeTableCodes
            };
        }

        [HttpPut]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainQuestion)]
        public async Task<dynamic> Update(int id, QuestionModel question)
        {
            if (question == null) throw new ArgumentNullException(nameof(question));
            if (string.IsNullOrWhiteSpace(question.Code) && string.IsNullOrWhiteSpace(question.Question))
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            var item = await _dbContext.Set<Question>().SingleOrDefaultAsync(_ => _.Id == id);
            if (item == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            item.Code = question.Code;
            item.QuestionString = question.Question;
            item.Instructions = question.Instructions;
            item.YesNoRequired = question.YesNo;
            item.CountRequired = question.Count;
            item.AmountRequired = question.Amount;
            item.EmployeeRequired = question.Staff;
            item.TextRequired = question.Text;
            item.PeriodTypeRequired = question.Period;
            item.TableType = question.ListType;

            await _dbContext.SaveChangesAsync();

            return new
            {
                Result = "success",
                UpdatedId = item.Id,
                Key = id
            };
        }

        [HttpDelete]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainQuestion)]
        public dynamic Delete(int id)
        {
            try
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext.Set<Question>().SingleOrDefault(_ => _.Id == id);
                    if (model == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.QuestionDoesNotExist.ToString());
                    _dbContext.Set<Question>().Remove(model);
                    _dbContext.SaveChanges();
                    tcs.Complete();
                }

                return new
                {
                    Result = "success"
                };
            }
            catch (Exception ex)
            {
                if (!ex.IsForeignKeyConstraintViolation())
                    throw;

                return KnownSqlErrors.CannotDelete.AsHandled();
            }
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainQuestion)]
        public async Task<dynamic> Create(QuestionModel question)
        {
            if (question == null) throw new ArgumentNullException(nameof(question));
            if (string.IsNullOrWhiteSpace(question.Code) && string.IsNullOrWhiteSpace(question.Question))
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            Question newQuestion;
            using (var ts = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled))
            {
                var newId = _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Question);
                newQuestion = _dbContext.Set<Question>().Add(new Question((short)newId, question.Question)
                {
                    Code = question.Code,
                    YesNoRequired = question.YesNo,
                    CountRequired = question.Count,
                    AmountRequired = question.Amount,
                    EmployeeRequired = question.Staff,
                    TextRequired = question.Text,
                    PeriodTypeRequired = question.Period,
                    TableType = question.ListType,
                    Instructions = question.Instructions
                });

                await _dbContext.SaveChangesAsync();

                ts.Complete();
            }
            return new
            {
                Result = "success",
                UpdatedId = newQuestion.Id,
                Key = newQuestion.Id
            };

        }
    }

    public class QuestionModel
    {
        public int? Id { get; set; }
        [MaxLength(10)]
        public string Code { get; set; }
        [MaxLength(100)]
        public string Question { get; set; }
        public int? YesNo { get; set; }
        public int? Period { get; set; }
        public int? Count { get; set; }
        public int? Amount { get; set; }
        public int? Text { get; set; }
        public int? Staff { get; set; }
        public short? ListType { get; set; }
        [MaxLength(254)]
        public string Instructions { get; set; }
    }

    public class QuestionItem
    {
        [PicklistKey]
        public int Key { get; set; }
        [PicklistCode]
        public string Code { get; set; }
        [PicklistDescription]
        public string Question { get; set; }
        public string Instructions { get; set; }
        public string YesNoValue { get; set; }
        public string CountValue { get; set; }
        public string AmountValue { get; set; }
        public string TextValue { get; set; }
        public string StaffValue { get; set; }
        public string PeriodValue { get; set; }
        public string List { get; set; }
        public decimal? YesNo { get; set; }
        public decimal? Period { get; set; }
        public decimal? Count { get; set; }
        public decimal? Amount { get; set; }
        public decimal? Text { get; set; }
        public decimal? Staff { get; set; }
        public short? ListType { get; set; }
    }
}