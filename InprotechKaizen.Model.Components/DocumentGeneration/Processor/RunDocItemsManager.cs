using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Processor
{
    public interface IRunDocItemsManager
    {
        IEnumerable<ItemProcessor> Execute(IList<ItemProcessor> itemProcessors);
    }

    public class RunDocItemsManager : IRunDocItemsManager
    {
        readonly IDbContext _dbContext;
        readonly List<ReferencedDataItem> _docItems = new List<ReferencedDataItem>();
        readonly ILegacyDocItemRunner _runner;

        public RunDocItemsManager(IDbContext dbContext, ILegacyDocItemRunner runner)
        {
            _runner = runner;
            _dbContext = dbContext;
        }

        public IEnumerable<ItemProcessor> Execute(IList<ItemProcessor> itemProcessors)
        {
            var runDocItemParams = _runner.GetDocItemSiteControls();

            var allReferencedDocItemNames = itemProcessors.Select(_ => _.ReferencedDataItem?.ItemName).Distinct();

            var allReferencedDocItems = (from i in _dbContext.Set<DocItem>()
                                         where allReferencedDocItemNames.Contains(i.Name)
                                         select new ReferencedDataItem
                                         {
                                             ItemKey = i.Id,
                                             ItemName = i.Name,
                                             ItemType = (DataItemType?) i.ItemType,
                                             EntryPointUsage = i.EntryPointUsage,
                                             SqlQuery = i.Sql
                                         }).ToDictionary(k => k.ItemName, v => v, StringComparer.InvariantCultureIgnoreCase);

            var mapDocItemResults = new Dictionary<ItemProcessor, List<TableResultSet>>();

            foreach (var itemProcessor in itemProcessors)
            {
                if (itemProcessor.ReferencedDataItem == null || string.IsNullOrEmpty(itemProcessor.ReferencedDataItem.ItemName))
                {
                    itemProcessor.Exception = new ItemProcessorException(ItemProcessErrorReason.DocItemNullOrEmpty);
                    continue;
                }

                itemProcessor.EmptyValue = runDocItemParams.SingleSpaceBookmarksAsNull ? string.Empty : " ";
                itemProcessor.DateStyle = runDocItemParams.DateStyle;

                try
                {
                    if (!TryGetDocItem(itemProcessor, allReferencedDocItems, out var referencedDataItem))
                    {
                        continue;
                    }

                    _docItems.Add(referencedDataItem);

                    itemProcessor.ReferencedDataItem = referencedDataItem;

                    List<TableResultSet> tableResultSets;
                    if (!mapDocItemResults.ContainsKey(itemProcessor))
                    {
                        tableResultSets = _runner.Execute(itemProcessor.ReferencedDataItem,
                                                          itemProcessor.Parameters,
                                                          itemProcessor.EntryPointValue,
                                                          itemProcessor.RowsReturnedMode).ToList();

                        mapDocItemResults.Add(itemProcessor, tableResultSets);
                    }
                    else
                    {
                        tableResultSets = mapDocItemResults[itemProcessor];
                    }

                    itemProcessor.TableResultSets = tableResultSets;
                }
                catch (Exception ex)
                {
                    itemProcessor.Exception = ex;
                }

                yield return itemProcessor;
            }
        }

        bool TryGetDocItem(ItemProcessor itemProcessor, Dictionary<string, ReferencedDataItem> dataItemRepository, out ReferencedDataItem referencedDataItem)
        {
            referencedDataItem = _docItems.FirstOrDefault(d => d.ItemName == itemProcessor.ReferencedDataItem.ItemName);

            if (referencedDataItem == null)
            {
                dataItemRepository.TryGetValue(itemProcessor.ReferencedDataItem.ItemName, out referencedDataItem);
            }

            if (referencedDataItem == null)
            {
                itemProcessor.Exception = new ItemProcessorException(ItemProcessErrorReason.DocItemNotFound,
                                                                     $"Cannot find Item with name '{itemProcessor.ReferencedDataItem.ItemName}'.");

                return false;
            }

            if (!referencedDataItem.ItemType.HasValue)
            {
                itemProcessor.Exception = new ItemProcessorException(ItemProcessErrorReason.ItemTypeNotSet,
                                                                     $"'{itemProcessor.ReferencedDataItem.ItemName}' has the ITEM_TYPE column set to nothing.");
                return false;
            }

            if (!string.IsNullOrEmpty(referencedDataItem.SqlQuery)) return true;

            itemProcessor.Exception = new ItemProcessorException(ItemProcessErrorReason.SQLQueryNotSet,
                                                                 $"'{itemProcessor.ReferencedDataItem.ItemName}' has the SQL_QUERY column set to nothing.");

            return false;
        }
    }
}