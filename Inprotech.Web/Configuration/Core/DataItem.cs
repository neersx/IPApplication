using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Documents;

namespace Inprotech.Web.Configuration.Core
{
    public class DataItemPayload
    {
        public EntryPoint EntryPointUsage { get; set; }

        public bool ReturnsImage { get; set; }

        public bool UseSourceFile { get; set; }

        public bool IsSqlStatement { get; set; }
        
        public Sql Sql { get; set; }

        public IEnumerable<DataItemGroup> ItemGroups { get; set; }

        public string Notes { get; set; }

        public string CreatedBy { get; set; }

        public short? ItemType { get; set; }
    }

    public class Sql
    {
        public string SqlStatement { get; set; }
        public string StoredProcedure { get; set; }
    }

    public class EntryPoint
    {
        public short? Name { get; set; }
        public string Description { get; set; }
    }

    public class DataItemEntity : DataItemPayload
    {
        public int Id { get; set; }
       
        [Required]
        [MaxLength(40)]
        public string Name { get; set; }
      
        [Required]
        public string Description { get; set; }
    }

    public static class DataItemTranslator
    {
        public static DocItem FromSaveDetails(this DocItem dataItem, dynamic entity)
        {
            dataItem.Id = entity is DataItem ? entity.Key : entity.Id;
            dataItem.Name = entity is DataItem ? entity.Code : entity.Name;
            dataItem.Description = entity is DataItem ? entity.Value : entity.Description;
            dataItem.EntryPointUsage = entity.EntryPointUsage?.Name;
            dataItem.ItemType = entity.IsSqlStatement ? Convert.ToInt16(ItemType.SqlStatement)
                : entity.UseSourceFile ? Convert.ToInt16(ItemType.StoredProcedureExternalDataSource)
                    : Convert.ToInt16(ItemType.StoredProcedure);
            dataItem.Sql = entity.IsSqlStatement ? entity.Sql.SqlStatement : entity.Sql.StoredProcedure;
            dataItem.SqlDescribe = entity.ReturnsImage ? "9" : null;
            dataItem.Note = !string.IsNullOrEmpty(entity.Notes)
                ? new ItemNote
                {
                    ItemId = dataItem.Id,
                    ItemNotes = entity.Notes
                }
                : null;

            return dataItem;
        }

        public static dynamic ToSaveDetails(this DataItemPayload payload, DocItem dataItem, IDataItemMaintenance dataItemMaintenance)
        {
            return new
            {
                PayloadInfo = new DataItemPayload
                {
                    Notes = dataItem.Note?.ItemNotes,
                    ReturnsImage = dataItem.ReturnsImage(),
                    IsSqlStatement = dataItem.ItemType == Convert.ToInt16(ItemType.SqlStatement),
                    UseSourceFile = dataItem.ItemType == Convert.ToInt16(ItemType.StoredProcedureExternalDataSource),
                    EntryPointUsage = dataItemMaintenance.EntryPoint(dataItem),
                    Sql = new Sql
                    {
                        StoredProcedure = dataItem.ItemType != Convert.ToInt16(ItemType.SqlStatement) ? dataItem.Sql : string.Empty,
                        SqlStatement = dataItem.ItemType == Convert.ToInt16(ItemType.SqlStatement) ? dataItem.Sql : string.Empty
                    },
                    CreatedBy = dataItem.CreatedBy,
                    ItemGroups = dataItemMaintenance.DataItemGroups(dataItem.Id)
                },
                KeyInfo = new
                {
                    dataItem.Id,
                    dataItem.Name,
                    dataItem.Description
                }
            };
        }
    }

    public enum ItemType : short
    {
        SqlStatement = 0,
        StoredProcedure = 1,
        StoredProcedureExternalDataSource = 3
    }
}
