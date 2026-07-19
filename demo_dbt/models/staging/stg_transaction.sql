select
 transactionid,
 transactiondt,
 transactionamt,
 card1,
 card2,
 addr1,
 isfraud
from {{source('raw','train_transaction')}}
