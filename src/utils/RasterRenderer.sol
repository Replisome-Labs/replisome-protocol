// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Strings} from "../libraries/Strings.sol";

library RasterRenderer {
    using Strings for uint256;
    using Strings for address;
    using Strings for bytes4;
    using Strings for bytes;

    struct Params {
        address metadata;
        uint256 metadataId;
        uint256 width;
        uint256 height;
        bytes4[] colors;
        bytes data;
    }

    string public constant script =
        'function t(t,n,e,i,o){t.width=n*i*o,t.height=e*i*o,t.style.width=`${n*i}px`,t.style.height=`${e*i}px`,t.getContext("2d").scale(o,o)}function n(t,n,i,a,d,c){const u=t.getContext("2d");u.clearRect(0,0,i*n,a*n);const l=r(c);for(let t=0;t<l;t++){const r=parseInt(s(c,t,t+1),16)-1;if(-1===r)continue;const a=o(d[r]),{x:l,y:g}=e(t,i);u.fillStyle=`rgba(${a.r}, ${a.g}, ${a.b}, ${a.a})`,u.fillRect(l*n,g*n,n,n)}}function e(t,n){return{x:Math.floor(t%n),y:Math.floor(t/n)}}function i(t,n=0,e=Math.pow(10,n)){return Math.round(e*t)/e}function o(t){return"#"===t[0]&&(t=t.substring(1)),{r:parseInt(t.substring(0,2),16),g:parseInt(t.substring(2,4),16),b:parseInt(t.substring(4,6),16),a:8===t.length?i(parseInt(t.substring(6,8),16)/255,2):1}}function r(t){return(t.length-2)/2}function s(t,n,e){return n=2+2*n,null!=e?"0x"+t.substring(n,2+2*e):"0x"+t.substring(n)}window.addEventListener("load",function(){const{metadata:e,metadataId:i,width:o,height:r,colors:s,data:a}=tokenData;document.title=`HiggsPixel - ${e}/${i}`;const d=document.createElement("canvas");function c(){const e=window.devicePixelRatio,i=Math.min(window.innerWidth/o,window.innerHeight/r);t(d,o,r,i,e),n(d,i,o,r,s,a)}c(),document.body.appendChild(d),window.addEventListener("resize",c),window.screen.orienration&&window.screen.orientation.addEventListner("change",c)});';

    string private constant _template_start =
        '<!DOCTYPE html><html><head><meta charset="utf-8"><style type="text/css">body{margin:0;padding:0}canvas{padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0}</style></head><body>';
    string private constant _template_end = "</body></html>";
    string private constant _script_tag_start = "<script>";
    string private constant _script_tag_end = "</script>";

    function generateHTML(Params memory params)
        external
        pure
        returns (string memory html)
    {
        html = string(
            abi.encodePacked(
                _template_start,
                _script_tag_start,
                _generateTokenData(params),
                _script_tag_end,
                _script_tag_start,
                script,
                _script_tag_end,
                _template_end
            )
        );
    }

    function _generateTokenData(Params memory params)
        private
        pure
        returns (string memory js)
    {
        js = string(
            abi.encodePacked(
                'const tokenData = { metadata: "',
                params.metadata.toHexString(),
                '", metadataId: ',
                params.metadataId.toString(),
                ", width: ",
                params.width.toString(),
                ", height: ",
                params.height.toString(),
                ", colors: [",
                _formatColors(params.colors),
                '], data: "',
                params.data.toHexString(),
                '"}'
            )
        );
    }

    function _formatColors(bytes4[] memory colors)
        private
        pure
        returns (string memory js)
    {
        js = "";
        for (uint256 i = 0; i < colors.length; i++) {
            if (i == 0) {
                js = string(
                    abi.encodePacked(js, '"#', colors[i].toColorString(), '"')
                );
            } else {
                js = string(
                    abi.encodePacked(js, ', "#', colors[i].toColorString(), '"')
                );
            }
        }
    }
}
