using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("ACTIONS")]
    public class Action
    {
        [Obsolete("For persistence only.")]
        public Action()
        {
        }

        public Action(string name, Importance importance = null, short numberOfCyclesAllowed = 1, string id = null)
        {
            if (string.IsNullOrEmpty(name)) throw new ArgumentException("A valid name is required.");

            Name = name;
            NumberOfCyclesAllowed = numberOfCyclesAllowed;

            if (importance != null)
                ImportanceLevel = importance.Level;
            if (id != null)
                Code = id;
        }

        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Key]
        [Column("ACTION")]
        [MaxLength(2)]
        public string Code { get; set; }

        [MaxLength(50)]
        [Column("ACTIONNAME")]
        public string Name { get; set; }

        [Column("ACTIONNAME_TID")]
        public int? NameTId { get; set; }

        [Column("ACTIONTYPEFLAG")]
        public decimal? ActionType { get; set; }
        
        [Column("NUMCYCLESALLOWED")]
        public short? NumberOfCyclesAllowed { get; set; }

        [MaxLength(2)]
        [Column("IMPORTANCELEVEL")]
        public string ImportanceLevel { get; set; }

        public bool IsCyclic => NumberOfCyclesAllowed > 1;
    }
}