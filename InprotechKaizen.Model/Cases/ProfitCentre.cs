using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Cases
{
    [Table("PROFITCENTRE")]
    public class ProfitCentre
    {
        [Obsolete("For persistence only.")]
        public ProfitCentre()
        {
        }

        public ProfitCentre(string id, string name)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Profit Centre is required.");
            if(string.IsNullOrWhiteSpace(id)) throw new ArgumentException("A valid id is required.");

            Name = name;
            Id = id;
        }
        public ProfitCentre(string id, string name, Name entity)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Profit Centre is required.");
            if(string.IsNullOrWhiteSpace(id)) throw new ArgumentException("A valid id is required.");

            Name = name;
            Id = id;
            EntityName = entity;
            EntityId = entity.Id;
        }

        [Key]
        [MaxLength(6)]
        [Column("PROFITCENTRECODE")]
        public string Id { get; set; }

        [MaxLength(50)]
        [Column("DESCRIPTION")]
        public string Name { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? NameTId { get; set; }

        [Column("ENTITYNO")]
        public int? EntityId { get; set; }

        public virtual Name EntityName { get; protected set; }

        public override string ToString()
        {
            return Name;
        }
    }
}