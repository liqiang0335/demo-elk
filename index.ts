/**
 * 写入测试数据到 source
 */

import { writeFileSync } from 'fs';
import { join } from 'path';
import dayjs from 'dayjs';

const mock_1 = () => `/116.147.11.22:64871 - {"header":{"msgId":${Date.now()},"msgType":"request","subType":"upload"},"device":{"gatewaySn":"MA250201"},"payload":{"dataType":"compactness","dataList":[{"data":[2874,3174,3042,3127],"channelState":[1,1,1,1],"time":1743263941000},{"data":[2872,3174,3038,3125],"channelState":[1,1,1,1],"time":1743263943000},{"data":[2883,3187,3047,3139],"channelState":[1,1,1,1],"time":1743263945000},{"data":[2878,3178,3041,3127],"channelState":[1,1,1,1],"time":1743263947000},{"data":[2878,3179,3040,3126],"channelState":[1,1,1,1],"time":1743263949000},{"data":[2881,3180,3041,3126],"channelState":[1,1,1,1],"time":1743263951000},{"data":[2882,3181,3039,3130],"channelState":[1,1,1,1],"time":1743263953000},{"data":[2882,3182,3041,3130],"channelState":[1,1,1,1],"time":1743263955000},{"data":[2877,3183,3040,3129],"channelState":[1,1,1,1],"time":1743263957000},{"data":[2876,3183,3041,3129],"channelState":[1,1,1,1],"time":1743263959000},{"data":[2877,3185,3041,3129],"channelState":[1,1,1,1],"time":1743263961000},{"data":[2872,3186,3042,3130],"channelState":[1,1,1,1],"time":1743263963000},{"data":[2876,3187,3042,3129],"channelState":[1,1,1,1],"time":1743263965000},{"data":[2873,3188,3043,3129],"channelState":[1,1,1,1],"time":1743263967000},{"data":[2876,3188,3035,3130],"channelState":[1,1,1,1],"time":1743263969000},{"data":[2876,3189,3034,3132],"channelState":[1,1,1,1],"time":1743263971000},{"data":[2881,3190,3036,3131],"channelState":[1,1,1,1],"time":1743263973000},{"data":[2883,3191,3038,3132],"channelState":[1,1,1,1],"time":1743263975000},{"data":[2888,3193,3038,3133],"channelState":[1,1,1,1],"time":1743263977000},{"data":[2889,3193,3040,3132],"channelState":[1,1,1,1],"time":1743263979000},{"data":[2884,3194,3036,3132],"channelState":[1,1,1,1],"time":1743263981000},{"data":[2883,3196,3038,3131],"channelState":[1,1,1,1],"time":1743263983000},{"data":[2885,3196,3037,3130],"channelState":[1,1,1,1],"time":1743263985000},{"data":[2886,3197,3038,3130],"channelState":[1,1,1,1],"time":1743263987000},{"data":[2886,3198,3037,3131],"channelState":[1,1,1,1],"time":1743263989000},{"data":[2888,3199,3034,3132],"channelState":[1,1,1,1],"time":1743263991000},{"data":[2886,3200,3036,3132],"channelState":[1,1,1,1],"time":1743263993000},{"data":[2895,3212,3042,3143],"channelState":[1,1,1,1],"time":1743263995000},{"data":[2887,3201,3035,3136],"channelState":[1,1,1,1],"time":1743263997000}],"sn":"CF250203","bat":81}}`
const mock_2 = () => `/101.205.189.206:54094 - {"heartbeat":"MA250102"}`
const mock_3 = () => `/116.147.11.22:64873 - {"header":{"msgId":${Date.now()},"msgType":"request","subType":"upload"},"device":{"gatewaySn":"MA250201"},"payload":{"dataType":"compactness","dataList":[{"data":[2878,3179,3040,3126],"channelState":[1,1,1,1],"time":1743263948000}],"sn":"CF250203","bat":81}}`
const mock_4 = () => `/116.147.11.22:64874 - {"header":{"msgId":${Date.now()},"msgType":"request","subType":"upload"},"device":{"gatewaySn":"MA250201"},"payload":{"dataType":"compactness","dataList":[{"data":[2878,3179,3040,3126],"channelState":[1,1,1,1],"time":1743263948000}],"sn":"CF250203","bat":81}}`

const mockData = [mock_1, mock_2, mock_3, mock_4]
  .map((item, index) => {
    const time = dayjs().add(index, 's').format('YYYY-MM-DD HH:mm:ss');
    return `[${time}] ${item()}\n`;
  })
  .join('');
const filePath = join(process.cwd(), 'source', dayjs().format('YYYY-MM-DD HH:mm:ss') + '.log');


// 写入测试数据
writeFileSync(filePath, mockData, 'utf8');
console.log(`测试数据已写入: ${filePath}`);