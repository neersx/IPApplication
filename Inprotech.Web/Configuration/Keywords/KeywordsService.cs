using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Extentions;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Keywords;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Keywords
{
    public interface IKeywords
    {
        Task<KeywordItems> GetKeywordByNo(int keywordNo);
        Task<IEnumerable<KeywordItems>> GetKeywords();
        Task<int> SubmitKeyWordForm(KeywordItems model);
        Task<DeleteResponseModel> DeleteKeywords(DeleteRequestModel deleteRequestModel);
    }
    public class KeywordsService : IKeywords
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;
        public KeywordsService(IDbContext dbContext, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            _dbContext = dbContext;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }
        public async Task<IEnumerable<KeywordItems>> GetKeywords()
        {
            return await (from k in _dbContext.Set<Keyword>()
                          select new KeywordItems
                          {
                              KeywordNo = k.KeywordNo,
                              KeyWord = k.KeyWord,
                              CaseStopWord = k.StopWord == 1 || k.StopWord == 3,
                              NameStopWord = k.StopWord == 2 || k.StopWord == 3
                          }).ToListAsync();
        }

        public async Task<KeywordItems> GetKeywordByNo(int keywordNo)
        {
            var result = await _dbContext.Set<Keyword>()
                                    .Select(k => new KeywordItems
                                    {
                                        KeywordNo = k.KeywordNo,
                                        KeyWord = k.KeyWord,
                                        CaseStopWord = k.StopWord == 1 || k.StopWord == 3,
                                        NameStopWord = k.StopWord == 2 || k.StopWord == 3
                                    }).FirstOrDefaultAsync(x => x.KeywordNo == keywordNo);

            if (result == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            var synonyms = await (from s in _dbContext.Set<Synonyms>().Where(_ => _.KeywordNo == keywordNo)
                                  join k in _dbContext.Set<Keyword>() on s.KwSynonym equals k.KeywordNo
                                  select new Synonym { Key = k.KeyWord, Id = k.KeywordNo }).ToArrayAsync();

            result.Synonyms = synonyms;
            return result;
        }

        public async Task<int> SubmitKeyWordForm(KeywordItems model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            var keyword = await _dbContext.Set<Keyword>().FirstOrDefaultAsync(x => x.KeywordNo == model.KeywordNo);
            if (keyword != null)
            {

                keyword.StopWord = GetStopWord(model);
                keyword.KeyWord = model.KeyWord;
            }
            else
            {
                keyword = new Keyword
                {
                    KeyWord = model.KeyWord,
                    StopWord = GetStopWord(model),
                    KeywordNo = _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Keywords)
                };

                _dbContext.Set<Keyword>().Add(keyword);
            }

            await _dbContext.SaveChangesAsync();

            var synonymsToBeDeleted = _dbContext.Set<Synonyms>().Where(_ => _.KeywordNo == keyword.KeywordNo);
            if (synonymsToBeDeleted.Any()) _dbContext.RemoveRange(synonymsToBeDeleted);

            if (model.Synonyms == null) return keyword.KeywordNo;

            foreach (var syn in model.Synonyms)
            {
                var newSyn = new Synonyms
                {
                    KeywordNo = keyword.KeywordNo,
                    KwSynonym = syn.Id
                };

                _dbContext.Set<Synonyms>().Add(newSyn);
            }

            await _dbContext.SaveChangesAsync();

            return keyword.KeywordNo;
        }

        decimal GetStopWord(KeywordItems model)
        {
            return (!model.CaseStopWord && !model.NameStopWord)
                ? 0
                : ((model.CaseStopWord && model.NameStopWord)
                    ? 3
                    : ((model.CaseStopWord && !model.NameStopWord) ? 1 : 2));
        }

        public async Task<DeleteResponseModel> DeleteKeywords(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null || !deleteRequestModel.Ids.Any()) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();

            using (var txScope = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var keywords = _dbContext.Set<Keyword>().Where(_ => deleteRequestModel.Ids.Contains(_.KeywordNo)).ToArray();

                foreach (var key in keywords)
                {
                    try
                    {
                        var synonymsToBeDeleted = _dbContext.Set<Synonyms>().Where(_ => _.KeywordNo == key.KeywordNo);
                        if (synonymsToBeDeleted.Any()) _dbContext.RemoveRange(synonymsToBeDeleted);

                        _dbContext.Set<Keyword>().Remove(key);
                        await _dbContext.SaveChangesAsync();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(key.KeywordNo);
                        }
                        _dbContext.Detach(key);
                    }
                }

                txScope.Complete();

                if (response.InUseIds.Any())
                {
                    response.HasError = true;
                    response.Message = ConfigurationResources.InUseErrorMessage;
                }
            }
            return response;
        }
    }

    public class KeywordItems
    {
        public int? KeywordNo { get; set; }
        public string KeyWord { get; set; }
        public bool CaseStopWord { get; set; }
        public bool NameStopWord { get; set; }
        public IEnumerable<Synonym> Synonyms { get; set; }
    }

    public class Synonym
    {
        public int Id { get; set; }
        public string Key { get; set; }
    }

}
