using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration.Screens
{
    [Table("TOPICCONTROLFILTER")]
    public class TopicControlFilter
    {
        [Obsolete("For persistence only.")]
        public TopicControlFilter()
        {
        }

        public TopicControlFilter(string filterName, string filterValue)
        {
            FilterName = filterName;
            FilterValue = filterValue;
        }

        [Column("TOPICCONTROLFILTERNO")]
        public int Id { get; protected set; }

        [MaxLength(50)]
        [Column("FILTERNAME")]
        public string FilterName { get; set; }

        [MaxLength(254)]
        [Column("FILTERVALUE")]
        public string FilterValue { get; set; }
    }
}