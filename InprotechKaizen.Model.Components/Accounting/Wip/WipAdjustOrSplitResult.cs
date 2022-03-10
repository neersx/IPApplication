namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public class WipAdjustOrSplitResult
    {
        public int ErrorCode { get; set; }
        
        public string Error { get; set; }
        
        public int? EntryNo { get; set; }

        public int? NewTransKey { get; set; }

        public short? NewWipSeqKey { get; set; }
    }
}