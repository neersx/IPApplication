using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.CustomContent
{
    public interface ICustomContentDataResolver
    {
        CustomContentData Resolve(int docItemKey, string entryPoint);
    }

    public class CustomContentDataResolver : ICustomContentDataResolver
    {
        readonly IDbContext _dbContext;
        readonly ILegacyDocItemRunner _legacyDocItemRunner;

        public CustomContentDataResolver(IDbContext dbContext, ILegacyDocItemRunner legacyDocItemRunner)
        {
            _dbContext = dbContext;
            _legacyDocItemRunner = legacyDocItemRunner;
        }

        public CustomContentData Resolve(int docItemKey, string entryPoint)
        {
            var docItem = _dbContext.Set<DocItem>().Where(_ => _.Id == docItemKey).Select(_ => new ReferencedDataItem
            {
                ItemKey = _.Id,
                EntryPointUsage = _.EntryPointUsage,
                ItemName = _.Name,
                ItemDescription = _.Description,
                ItemType = (DataItemType?) _.ItemType,
                SqlQuery = _.Sql
            }).FirstOrDefault();

            if (docItem == null)
            {
                throw new ArgumentException("Invalid DocItem");
            }
            
            var result = _legacyDocItemRunner.Execute(docItem, string.Empty, entryPoint, RowsReturnedMode.Single).ToList();

            return CustomContentData(result);
        }

        CustomContentData CustomContentData(IList<TableResultSet> result)
        {
            if (result == null || result.Count == 0)
            {
                return null;
            }

            var values = result[0].RowResultSets[0].Values;

            return new CustomContentData
            {
                CustomUrl = HttpUtility.UrlEncode(Uri.IsWellFormedUriString(values[0].ToString(), UriKind.Absolute) ? values[0].ToString() : string.Empty),
                Title = values.Count > 1 ? values[1].ToString() : string.Empty,
                ClassName = values.Count > 2 ? values[2].ToString() : string.Empty
            };
        }
    }

    public class CustomContentData
    {
        public string CustomUrl { get; set; }
        public string Title { get; set; }
        public string ClassName { get; set; }
    }
}